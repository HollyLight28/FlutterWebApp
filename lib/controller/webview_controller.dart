import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
          if ((error.isForMainFrame ?? false) && (error.errorType == WebResourceErrorType.hostLookup ||
              error.errorType == WebResourceErrorType.connect)) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
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
