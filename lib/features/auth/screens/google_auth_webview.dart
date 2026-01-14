import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleAuthWebView extends StatefulWidget {
  const GoogleAuthWebView({super.key});

  @override
  State<GoogleAuthWebView> createState() => _GoogleAuthWebViewState();
}

class _GoogleAuthWebViewState extends State<GoogleAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            // Check if we hit the callback URL
            if (url.contains('/auth/google/callback')) {
               _handleCallback();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://find-my-food-api.onrender.com/auth/login/google'));
  }

  Future<void> _handleCallback() async {
    try {
      // Extract the body of the page (assuming the API returns JSON in the body)
      final String jsonString = await _controller.runJavaScriptReturningResult(
        'document.body.innerText',
      ) as String;
      
      // The result might be a JSON string wrapped in quotes due to JS return
      // We clean it up
      String cleanJson = jsonString;
      if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
        cleanJson = cleanJson.substring(1, cleanJson.length - 1);
        // Unescape quotes if needed
        cleanJson = cleanJson.replaceAll(r'\"', '"').replaceAll(r'\\', r'\');
      }

      final data = jsonDecode(cleanJson);
      
      if (mounted) {
        if (data is Map<String, dynamic>) {
           Navigator.of(context).pop(data);
        } else {
           Navigator.of(context).pop({'error': 'Invalid response format'});
        }
      }
    } catch (e) {
      if (mounted) {
        // If parsing failed, maybe user just needs to tap "Continue" on the web page?
        // But assuming API returns raw JSON.
        // Let's verify if we can extract params from URL too just in case
        print('Error parsing Google Auth response: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Login'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
