import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh profile on open so the avatar URL (a short-lived presigned S3
    // link) is always current, even if the cached state holds a stale one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
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

              _buildAvatar(context, ref, user, userState.isLoading),

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
              
              // Payments hidden for this release — the paywall entry point is
              // removed. Subscription status still gates SOS on the home screen.
              if (AppConstants.paymentEnabled)
                _buildMenuItem(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'Подписка',
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
                onTap: () => context.push('/subscribe'),
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.description_outlined,
                title: 'Документы',
                onTap: () => _showDocumentsBottomSheet(context),
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Поддержка',
                onTap: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'alekseigradoboev553@gmail.com',
                  );
                  try {
                    await launchUrl(emailLaunchUri);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не удалось открыть почтовое приложение')),
                      );
                    }
                  }
                },
              ),
              
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'О приложении',
                onTap: () async {
                  final info = await PackageInfo.fromPlatform();
                  if (!context.mounted) return;
                  showAboutDialog(
                    context: context,
                    applicationName: 'Safe City',
                    applicationVersion: '${info.version} (${info.buildNumber})',
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
  
  Widget _buildAvatar(BuildContext context, WidgetRef ref, User? user, bool isLoading) {
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;
    final initial = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : user?.email.substring(0, 1).toUpperCase() ?? '?';

    return GestureDetector(
      onTap: isLoading ? null : () => _showAvatarOptions(context, ref, hasAvatar),
      child: Stack(
        children: [
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
            child: ClipOval(
              child: hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _avatarInitial(initial),
                    )
                  : _avatarInitial(initial),
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundLight, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref, bool hasAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(76),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Сделать фото', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Выбрать из галереи', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUpload(context, ref, ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Удалить фото', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final ok = await ref.read(userProvider.notifier).deleteAvatar();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Не удалось удалить фото')),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final ok = await ref.read(userProvider.notifier).uploadAvatar(picked.path);
      if (!ok && context.mounted) {
        final error = ref.read(userProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Не удалось загрузить фото')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось выбрать изображение')),
        );
      }
    }
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

  void _showDocumentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(76),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Документы',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined, color: AppColors.primary),
                title: const Text(
                  'Публичная оферта',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/documents',
                    extra: {
                      'title': 'Публичная оферта',
                      'url': 'https://www.safe-city.kz/legal/public-offer',
                    },
                  );
                },
              ),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                title: const Text(
                  'Политика конфиденциальности',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/documents',
                    extra: {
                      'title': 'Политика конфиденциальности',
                      'url': 'https://www.safe-city.kz/legal/privacy-policy',
                    },
                  );
                },
              ),
              const Divider(color: AppColors.surfaceBorder, height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                title: const Text(
                  'Пользовательское соглашение',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/documents',
                    extra: {
                      'title': 'Пользовательское соглашение',
                      'url': 'https://www.safe-city.kz/legal/terms-of-service',
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider).user;
    final nameController = TextEditingController(text: user?.fullName);
    final phoneController = TextEditingController(text: user?.phone);
    final secretPhraseController = TextEditingController(text: user?.secretPhrase);
    bool obscurePhrase = true;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Редактировать профиль'),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 16),
                TextField(
                  controller: secretPhraseController,
                  obscureText: obscurePhrase,
                  decoration: InputDecoration(
                    labelText: 'Секретный код',
                    hintText: 'Слово для отмены вызова',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePhrase ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setDialogState(() => obscurePhrase = !obscurePhrase),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Используется для подтверждения отмены вызова охраны',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
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
                  secretPhrase: secretPhraseController.text.isNotEmpty
                      ? secretPhraseController.text
                      : null,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
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
