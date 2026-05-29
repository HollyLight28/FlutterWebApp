import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controller/webview_controller.dart';
import 'jules_logo.dart';

class WebViewerScreen extends StatelessWidget {
  final String url;
  final WebViewerController controller;

  WebViewerScreen({super.key, required this.url})
      : controller = Get.put(WebViewerController(url));

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        body: Obx(() {
          if (!controller.hasInternetConnection.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const JulesLogo(size: 120),
                  const SizedBox(height: 40),
                  const Text('Could not load the page. Check your connection.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: controller.retryConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: RefreshIndicator(
              onRefresh: controller.retryConnection,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      // ПРИБРАНО BOTTOM PADDING
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24.0),
                      ),
                      child: WebViewWidget(controller: controller.webViewController),
                    ),
                  ),
                  if (controller.loadingPercentage.value > 0 &&
                      controller.loadingPercentage.value < 100)
                    Positioned(
                      top: MediaQuery.of(context).padding.top,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: controller.loadingPercentage.value / 100.0,
                        color: Theme.of(context).primaryColor,
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
