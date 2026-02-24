import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';

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
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(102),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Safe City',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Ваша безопасность — наш приоритет',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  
                  const Spacer(),
                  
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Войти по email',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: 'email@example.com',
                          ),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                          validator: _validateEmail,
                        ),
                        
                        if (authState.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            authState.error!,
                            style: const TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        
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
  }
}
