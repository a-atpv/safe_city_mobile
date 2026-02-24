import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });
  
  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );
    
    if (isOutlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: onPressed == null 
                  ? AppColors.textSecondary 
                  : AppColors.primary,
              width: 2,
            ),
          ),
          child: child,
        ),
      );
    }
    
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading
              ? AppColors.primaryGradient
              : null,
          color: onPressed == null || isLoading
              ? AppColors.textSecondary.withAlpha(76)
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(102),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      ),
    );
  }
}
