import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/models/user_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchSettings();
    });
  }

  Future<void> _updateSetting(UserSettings current, UserSettings updated) async {
    // Optimistic UI update could be done here or just rely on state
    await ref.read(userProvider.notifier).updateSettings(updated);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удаление аккаунта', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Вы действительно хотите удалить свой аккаунт? Это действие необратимо.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(userProvider.notifier).deleteAccount();
      if (success && mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final settings = state.settings ?? UserSettings(
      notificationsEnabled: true,
      callSoundEnabled: true,
      vibrationEnabled: true,
      language: 'ru',
      darkThemeEnabled: true,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('Уведомления'),
          _buildSwitchTile(
            title: 'Push-уведомления',
            value: settings.notificationsEnabled,
            onChanged: (val) => _updateSetting(settings, settings.copyWith(notificationsEnabled: val)),
          ),
          _buildSwitchTile(
            title: 'Звук звонка',
            value: settings.callSoundEnabled,
            onChanged: (val) => _updateSetting(settings, settings.copyWith(callSoundEnabled: val)),
          ),
          _buildSwitchTile(
            title: 'Вибрация',
            value: settings.vibrationEnabled,
            onChanged: (val) => _updateSetting(settings, settings.copyWith(vibrationEnabled: val)),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Приложение'),
          ListTile(
            title: const Text('Язык приложения', style: TextStyle(color: Colors.white)),
            subtitle: Text(settings.language.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onTap: () {
              // Language selector logic here
            },
          ),
          _buildSwitchTile(
            title: 'Тёмная тема',
            value: settings.darkThemeEnabled,
            onChanged: (val) => _updateSetting(settings, settings.copyWith(darkThemeEnabled: val)),
          ),
          
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Удалить аккаунт', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
