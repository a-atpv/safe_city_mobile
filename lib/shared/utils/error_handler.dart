import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../widgets/error_dialog.dart';
import '../../core/api/api_exception.dart';
import '../../l10n/l10n.dart';

class ErrorHandler {
  ErrorHandler._();

  static void showError(BuildContext context, dynamic error, {VoidCallback? onConfirm}) {
    final l10n = context.l10n;
    final String title;
    final String description;

    if (error is ApiException) {
      title = l10n.errorNetworkTitle;
      description = _sanitizeMessage(error.message);
    } else if (error is DioException) {
      title = l10n.errorNetworkTitle;
      description = _sanitizeMessage(ApiException.fromAny(error).message);
    } else if (error is String) {
      title = l10n.commonError;
      description = _sanitizeMessage(error);
    } else {
      title = l10n.errorGenericTitle;
      description = l10n.errorGenericBody;
    }

    ErrorDialog.show(
      context,
      title: title,
      description: description,
      onConfirm: onConfirm,
    );
  }

  static String _sanitizeMessage(String message) {
    if (message.isEmpty) return currentL10n.errorUnknown;

    // Remove technical details like "DioException", "Exception:", etc.
    String cleanMessage = message
        .replaceAll(RegExp(r'^(Exception|DioException|Error):\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]\s*', caseSensitive: false), '') // Remove things like [404]
        .split('\n')
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => message)
        .trim();

    if (cleanMessage.contains(
      'This exception was thrown because the response has a status code',
    )) {
      return currentL10n.errorRequestFailed;
    }

    // Limit length to ensure it fits the screen as requested
    if (cleanMessage.length > 150) {
      cleanMessage = '${cleanMessage.substring(0, 147)}...';
    }

    return cleanMessage;
  }
}
