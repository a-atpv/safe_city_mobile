import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/emergency_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int callId;
  const ReviewScreen({super.key, required this.callId});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    setState(() => _isLoading = true);
    await ref.read(emergencyProvider.notifier).submitReview(
      widget.callId,
      _rating,
      _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
    if (mounted) {
      context.go('/home');
    }
  }

  void _skip() {
    context.go('/home');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildStar(int index) {
    final isSelected = index <= _rating;
    return GestureDetector(
      onTap: () => setState(() => _rating = index),
      child: Icon(
        isSelected ? Icons.star : Icons.star_border,
        color: isSelected ? Colors.amber : AppColors.textSecondary,
        size: 48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Вызов завершён',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Оцените работу экипажа',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => _buildStar(index + 1)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _commentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Комментарий (необязательно)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Отправить отзыв', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skip,
                child: const Text('Пропустить', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
