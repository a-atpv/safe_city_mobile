import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Профиль',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              
              const SizedBox(height: 32),
              
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(51),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    user?.fullName?.isNotEmpty == true
                        ? user!.fullName![0].toUpperCase()
                        : user?.email.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                user?.fullName ?? 'Пользователь',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              if (user?.phone != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.phone!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              
              const SizedBox(height: 32),
              
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                title: 'Личные данные',
                onTap: () => _showEditProfileDialog(context, ref),
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.credit_card_outlined,
                title: 'Управление подпиской',
                trailing: user?.hasActiveSubscription == true
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Активна',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : null,
                onTap: () {},
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.description_outlined,
                title: 'Документы',
                onTap: () {},
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Поддержка',
                onTap: () {},
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'О приложении',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Safe City',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 Safe City',
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: 'Выйти',
                color: AppColors.error,
                onTap: () => _showLogoutDialog(context, ref),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () => _showDeleteAccountDialog(context, ref),
                child: const Text(
                  'Удалить аккаунт',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.textPrimary),
        title: Text(
          title,
          style: TextStyle(color: color ?? AppColors.textPrimary),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right,
          color: color ?? AppColors.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
  
  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider).user;
    final nameController = TextEditingController(text: user?.fullName);
    final phoneController = TextEditingController(text: user?.phone);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Редактировать профиль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                hintText: 'Введите ваше имя',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+7 (777) 123-45-67',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(userProvider.notifier).updateProfile(
                fullName: nameController.text,
                phone: phoneController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              ref.read(userProvider.notifier).clear();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить аккаунт?'),
        content: const Text(
          'Это действие необратимо. Все ваши данные будут удалены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              ref.read(userProvider.notifier).clear();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
