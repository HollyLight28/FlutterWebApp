import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewerController extends GetxController {
  final String url;
  late final WebViewController webViewController;

  Rx loadingPercentage = Rx(0);
  RxBool hasInternetConnection = RxBool(false);

  WebViewerController(this.url);

  @override
  void onInit() {
    initializeWebView();
    super.onInit();
  }

  void initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        // Allow only internal navigation
        onNavigationRequest: (request) async {
          if (request.url.contains('google.com') || request.url.contains('gstatic.com')) {
            return NavigationDecision.navigate;
          }
          await launchExternalUrl(request.url); // Open external in browser
          return NavigationDecision.prevent;
        },
        onProgress: (progress) => loadingPercentage.value = progress,
        onPageFinished: (_) => hasInternetConnection.value = true,
        // Detect network or DNS failure
        onWebResourceError: (error) {
          if (error.errorType == WebResourceErrorType.hostLookup ||
              error.errorType == WebResourceErrorType.connect) {
            hasInternetConnection.value = false;
            loadingPercentage.value = 0;
          }
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  // Retry reload if there was an error
  Future<void> retryConnection() async {
    hasInternetConnection.value = true;
    loadingPercentage.value = 0;
    webViewController.reload();
  }

  // Launch external links via default browser
  Future<void> launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Unable to handle your request');
    }
  }

  // Navigation helpers for back functionality
  Future<bool> canGoBack() async => await webViewController.canGoBack();

  void goBack() => webViewController.goBack();
}
