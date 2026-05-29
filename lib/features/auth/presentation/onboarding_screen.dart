import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/error_handler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secretPhraseController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _secretPhraseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(userProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          secretPhrase: _secretPhraseController.text.trim().isEmpty
              ? null
              : _secretPhraseController.text.trim(),
        );

    if (mounted) {
      if (success) {
        ref.read(authProvider.notifier).completeOnboarding();
        context.go('/home');
      } else {
        final error = ref.read(userProvider).error;
        ErrorHandler.showError(context, error);
      }
    }
  }

  Future<void> _skipOnboarding() async {
    final success = await ref
        .read(userProvider.notifier)
        .updateProfile(isNew: false);

    if (mounted) {
      if (success) {
        ref.read(authProvider.notifier).completeOnboarding();
        context.go('/home');
      } else {
        final error = ref.read(userProvider).error;
        ErrorHandler.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 40),

                                // Icon badge
                                Center(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withAlpha(
                                            80,
                                          ),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_add_outlined,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Heading
                                Center(
                                  child: Text(
                                    'Добро пожаловать!',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Center(
                                  child: Text(
                                    'Заполните данные профиля,\nчтобы продолжить',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.5,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // Form card
                                GlassContainer(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _label('Полное имя'),
                                          Text(
                                            ' *',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _nameController,
                                        keyboardType: TextInputType.name,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'Ваше имя и фамилия',
                                          icon: Icons.badge_outlined,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Пожалуйста, введите ваше имя';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      _label('Номер телефона'),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [
                                          PhoneInputFormatter()
                                        ],
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: '+7 (___) ___-__-__',
                                          icon: Icons.phone_outlined,
                                        ),
                                      ),

                                      const SizedBox(height: 4),
                                      Text(
                                        'Необязательно',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textHint,
                                            ),
                                      ),

                                      const SizedBox(height: 20),

                                      _label(
                                        'Секретное слово * (для отмены вызова)',
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _secretPhraseController,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _inputDecoration(
                                          hint: 'Секретное слово',
                                          icon: Icons.lock_outline,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Пожалуйста, введите секретное слово';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                const SizedBox(height: 32),

                                PrimaryButton(
                                  text: 'Продолжить',
                                  isLoading: userState.isLoading,
                                  onPressed: userState.isLoading
                                      ? null
                                      : _submit,
                                  width: double.infinity,
                                  icon: Icons.arrow_forward_rounded,
                                ),

                                const SizedBox(height: 16),

                                // Skip link
                                Center(
                                  child: TextButton(
                                    onPressed: userState.isLoading
                                        ? null
                                        : _skipOnboarding,
                                    child: Text(
                                      'Пропустить',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.textHint),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}