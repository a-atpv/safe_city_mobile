import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import '../../core/api/api_exception.dart';

class ErrorHandler {
  ErrorHandler._();

  static void showError(BuildContext context, dynamic error, {VoidCallback? onConfirm}) {
    final String title;
    final String description;

    if (error is ApiException) {
      title = 'Ошибка сети';
      description = _sanitizeMessage(error.message);
    } else if (error is String) {
      title = 'Ошибка';
      description = _sanitizeMessage(error);
    } else {
      title = 'Произошла ошибка';
      description = 'Что-то пошло не так. Пожалуйста, попробуйте позже.';
    }

    ErrorDialog.show(
      context,
      title: title,
      description: description,
      onConfirm: onConfirm,
    );
  }

  static String _sanitizeMessage(String message) {
    if (message.isEmpty) return 'Произошла неизвестная ошибка';

    // Remove technical details like "DioException", "Exception:", etc.
    String cleanMessage = message
        .replaceAll(RegExp(r'^(Exception|DioException|Error):\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]\s*', caseSensitive: false), '') // Remove things like [404]
        .split('\n')
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => message)
        .trim();

    // Limit length to ensure it fits the screen as requested
    if (cleanMessage.length > 150) {
      cleanMessage = '${cleanMessage.substring(0, 147)}...';
    }

    return cleanMessage;
  }
}
