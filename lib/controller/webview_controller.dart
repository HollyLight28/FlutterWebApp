import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:convert';
import 'dart:io';
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
    _initForegroundTask();
    super.onInit();
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'jules_foreground',
        channelName: 'Jules Active Session',
        channelDescription: 'Keep Jules AI active in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher_icon',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    if (await FlutterForegroundTask.isRunningService) {
       // already running
    } else {
       await FlutterForegroundTask.startService(
         notificationTitle: 'Jules AI is active',
         notificationText: 'Tap to return to the app',
       );
    }
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..addJavaScriptChannel(
        'NotificationChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            NotificationService.showNotification(
              id: DateTime.now().millisecond % 100000,
              title: data['title'] ?? 'Jules AI',
              body: data['body'] ?? '',
            );
          } catch (e) {
            NotificationService.showNotification(
              id: DateTime.now().millisecond % 100000,
              title: 'Jules AI',
              body: message.message,
            );
          }
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

        // Helper to send message to Flutter
        function sendToFlutter(title, options) {
          if (window.NotificationChannel) {
            const body = options && options.body ? options.body : "";
            window.NotificationChannel.postMessage(JSON.stringify({
              title: title,
              body: body
            }));
          }
        }

        // Mock Notification API
        const oldNotify = window.Notification;
        window.Notification = function(title, options) {
          sendToFlutter(title, options);
          return {
            close: () => {},
            onclick: null,
            onshow: null,
            onerror: null,
            onclose: null
          };
        };
        window.Notification.permission = "granted";
        window.Notification.requestPermission = () => Promise.resolve("granted");
        
        // Intercept ServiceWorker registration and notifications
        if ('serviceWorker' in navigator) {
          const originalRegister = navigator.serviceWorker.register;
          navigator.serviceWorker.register = function() {
            return originalRegister.apply(this, arguments).then(registration => {
              const originalShowNotification = registration.showNotification;
              registration.showNotification = function(title, options) {
                sendToFlutter(title, options);
                return Promise.resolve();
              };
              return registration;
            });
          };
        }

        // Periodically check for specific UI elements that might indicate a status change
        // if the site doesn't use standard Web Notifications API for everything
        setInterval(() => {
          const statusElement = document.querySelector('.jules-status-update'); // Example class
          if (statusElement && !statusElement.dataset.notified) {
            sendToFlutter("Jules Update", { body: statusElement.innerText });
            statusElement.dataset.notified = "true";
          }
        }, 5000);
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

  void openHistory() {
    webViewController.runJavaScript('''
      (function() {
        // Try to find history/menu button by common attributes
        const historySelectors = [
          'button[aria-label*="History"]',
          'button[aria-label*="menu"]',
          'header button:first-child',
          '.header button:first-child',
          'button svg path[d*="M12 8v4l3 3"]' // Example path for clock/history icon
        ];

        for (const selector of historySelectors) {
          const btn = document.querySelector(selector);
          if (btn) {
            btn.click();
            return;
          }
        }

        // Fallback to first button in header area
        const header = document.querySelector('header, .header, [role="banner"]');
        if (header) {
          const firstBtn = header.querySelector('button, [role="button"]');
          if (firstBtn) firstBtn.click();
        }
      })();
    ''');
  }

  void closePanel() {
    webViewController.runJavaScript('''
      (function() {
        const closeSelectors = [
          'button[aria-label*="Close"]',
          'button[aria-label*="close"]',
          '.close-button',
          'button svg path[d*="M18 6L6 18"]',
          'button svg path[d*="M6 18L18 6"]'
        ];

        for (const selector of closeSelectors) {
          const btn = document.querySelector(selector);
          if (btn) {
            btn.click();
            return;
          }
        }

        // Search by text content
        const closeButtons = Array.from(document.querySelectorAll('button, [role="button"]')).filter(b =>
          b.innerText.trim() === '✕' ||
          b.innerText.toLowerCase().includes('close')
        );
        if (closeButtons.length > 0) {
          closeButtons[0].click();
        }
      })();
    ''');
  }
}
