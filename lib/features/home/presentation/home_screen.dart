import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Fetch user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  void _onSosPressed() {
    final user = ref.read(userProvider).user;
    
    if (user == null || !user.hasActiveSubscription) {
      _showSubscriptionDialog();
      return;
    }
    
    context.push('/emergency');
  }
  
  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Подписка не активна'),
        content: const Text(
          'Для использования функции экстренного вызова необходима активная подписка.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Оформить'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final hasSubscription = user?.hasActiveSubscription ?? false;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Safe City',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (hasSubscription 
                          ? AppColors.success 
                          : AppColors.textSecondary).withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasSubscription ? Icons.check_circle : Icons.cancel,
                          color: hasSubscription 
                              ? AppColors.success 
                              : AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasSubscription ? 'Активна' : 'Не активна',
                          style: TextStyle(
                            color: hasSubscription 
                                ? AppColors.success 
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // SOS Button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    _onSosPressed();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse rings
                          ...List.generate(3, (index) {
                            final delay = index * 0.33;
                            final value = (_pulseController.value + delay) % 1.0;
                            return Container(
                              width: 200 + (value * 80),
                              height: 200 + (value * 80),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.sosRed.withAlpha(
                                    (76 * (1 - value)).toInt(),
                                  ),
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                          
                          // Glow
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sosRed.withAlpha(102),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          
                          // Button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: _isPressed ? 180 : 200,
                            height: _isPressed ? 180 : 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.sosRed,
                                  AppColors.sosRed.withRed(180),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.sosRed.withAlpha(153),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Instructions
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Нажмите для вызова охраны',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
