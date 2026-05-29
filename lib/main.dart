import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:julesbox/screen/webview_screen.dart';

// Website to be loaded inside the app
const websiteUrl = 'https://jules.google.com/u/0/session';

void main() {
  // Ensure Flutter widgets are prepared
  WidgetsFlutterBinding.ensureInitialized();

  // Enable full screen edge-to-edge mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Follow system theme
      debugShowCheckedModeBanner: false,
      home: WebViewerScreen(url: websiteUrl),
    );
  }
}
