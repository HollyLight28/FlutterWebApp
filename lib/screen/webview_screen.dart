import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controller/webview_controller.dart';

class WebViewerScreen extends StatelessWidget {
  final String url;
  final WebViewerController controller;

  WebViewerScreen({super.key, required this.url})
      : controller = Get.put(WebViewerController(url));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        if (!controller.hasInternetConnection.value) {
          return Scaffold(
            body: Center(
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
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: controller.retryConnection,
            child: Stack(
              children: [
                WebViewWidget(controller: controller.webViewController),
                if (controller.loadingPercentage.value > 0 &&
                    controller.loadingPercentage.value < 100)
                  LinearProgressIndicator(
                    value: controller.loadingPercentage.value / 100.0,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
centage.value < 100)
                  LinearProgressIndicator(
                    value: controller.loadingPercentage.value / 100.0,
                    color: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
