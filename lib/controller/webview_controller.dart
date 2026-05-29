import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'notification_service.dart';

class WebViewerController extends GetxController {
  final String url;
  late final WebViewController webViewController;

  RxInt loadingPercentage = 0.obs;
  RxBool hasInternetConnection = true.obs;

  WebViewerController(this.url);

  @override
  void onInit() {
    initializeWebView();
    NotificationService.init();
    super.onInit();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..addJavaScriptChannel(
        'NotificationChannel',
        onMessageReceived: (JavaScriptMessage message) {
          NotificationService.showNotification(
            id: DateTime.now().millisecond,
            title: 'Jules AI',
            body: message.message,
          );
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) async {
          if (request.url.contains('google.com') || request.url.contains('gstatic.com')) {
            return NavigationDecision.navigate;
          }
          await launchExternalUrl(request.url);
          return NavigationDecision.prevent;
        },
        onProgress: (progress) => loadingPercentage.value = progress,
        onPageFinished: (url) {
          hasInternetConnection.value = true;
          _injectNotificationListener();
        },
        onWebResourceError: (error) {
          if (error.errorType == WebResourceErrorType.hostLookup ||
              error.errorType == WebResourceErrorType.connect) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
          }
        },
      ));

    // Handle file picker for Android
    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (webViewController.platform as AndroidWebViewController)
          .setOnShowFileSelector(_androidFilePicker);
    }

    webViewController.loadRequest(Uri.parse(url));
  }

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    try {
      if (params.acceptTypes.any((type) => type == 'image/*')) {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: params.mode == FileSelectorMode.openMultiple,
        );
        if (result != null && result.files.isNotEmpty) {
          return result.files.map((e) => Uri.file(e.path!).toString()).toList();
        }
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.any,
          allowMultiple: params.mode == FileSelectorMode.openMultiple,
        );
        if (result != null && result.files.isNotEmpty) {
          return result.files.map((e) => Uri.file(e.path!).toString()).toList();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to pick file');
    }
    return [];
  }

  void _injectNotificationListener() {
    webViewController.runJavaScript('''
      (function() {
        if (window.NotificationInterceptorsSet) return;
        window.NotificationInterceptorsSet = true;

        const oldNotify = window.Notification;
        window.Notification = function(title, options) {
          if (window.NotificationChannel) {
            window.NotificationChannel.postMessage(title + (options && options.body ? ": " + options.body : ""));
          }
          return { close: () => {} };
        };
        window.Notification.permission = "granted";
        window.Notification.requestPermission = () => Promise.resolve("granted");
        
        // Handle service worker registration for push
        if ('serviceWorker' in navigator) {
          navigator.serviceWorker.register = () => Promise.resolve({
            showNotification: (title, options) => {
               if (window.NotificationChannel) {
                  window.NotificationChannel.postMessage(title + (options && options.body ? ": " + options.body : ""));
               }
            }
          });
        }
      })();
    ''');
  }

  Future<void> retryConnection() async {
    hasInternetConnection.value = true;
    loadingPercentage.value = 0;
    webViewController.reload();
  }

  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Unable to handle your request');
    }
  }

  Future<bool> canGoBack() async => await webViewController.canGoBack();
  void goBack() => webViewController.goBack();
}
