import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';

class DocumentsScreen extends StatelessWidget {
  final String title;
  final String url;

  const DocumentsScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: DocumentWebView(url: url),
    );
  }
}

class DocumentWebView extends StatefulWidget {
  final String url;

  const DocumentWebView({super.key, required this.url});

  @override
  State<DocumentWebView> createState() => _DocumentWebViewState();
}

class _DocumentWebViewState extends State<DocumentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Ignore minor errors or tracking/analytics domains failure if the main frame loaded.
            // On some platforms error.isForMainFrame is available.
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadingProgress = 0;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_hasError)
          WebViewWidget(controller: _controller),
        if (_isLoading && !_hasError)
          Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Загрузка... $_loadingProgress%',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_hasError)
          Container(
            color: AppColors.background,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      color: AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Не удалось загрузить страницу',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Пожалуйста, проверьте интернет-соединение и попробуйте снова.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Повторить', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
