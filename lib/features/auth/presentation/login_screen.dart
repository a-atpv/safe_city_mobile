import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/utils/error_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    return null;
  }
  
  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim().toLowerCase();
    
    final success = await ref.read(authProvider.notifier).requestOtp(email);
    
    if (success && mounted) {
      context.pushNamed('otp', extra: email);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ErrorHandler.showError(context, next.error);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/images/login_background_layer.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                  const Spacer(flex: 1),
                  
                  Container(
                    width: 120,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/icons/safe_city_shield.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Safe City',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Ваша безопасность — наш приоритет',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),
                  
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Text(
                        //   'Войти по email',
                        //   style: Theme.of(context).textTheme.titleMedium,
                        //   textAlign: TextAlign.center,
                        // ),
                        //
                        // const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'email@example.com',
                            fillColor: AppColors.surfaceBorder,
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          validator: _validateEmail,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        PrimaryButton(
                          text: 'Получить код',
                          isLoading: authState.isLoading,
                          onPressed: _requestOtp,
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Продолжая, вы соглашаетесь с условиями\nиспользования и политикой конфиденциальности',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
