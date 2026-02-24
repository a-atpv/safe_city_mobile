import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../shared/providers/providers.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    AppConstants.otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    AppConstants.otpLength,
    (_) => FocusNode(),
  );
  
  Timer? _resendTimer;
  int _resendSeconds = AppConstants.otpResendSeconds;
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }
  
  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }
  
  String get _code => _controllers.map((c) => c.text).join();
  
  Future<void> _verifyOtp() async {
    if (_code.length != AppConstants.otpLength) return;
    
    final success = await ref.read(authProvider.notifier).verifyOtp(
      widget.email,
      _code,
    );
    
    if (success && mounted) {
      await ref.read(userProvider.notifier).fetchUser();
      if (mounted) context.go('/home');
    }
  }
  
  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;
    
    await ref.read(authProvider.notifier).requestOtp(widget.email);
    _startResendTimer();
    
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
  }
  
  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < AppConstants.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    
    if (_code.length == AppConstants.otpLength) {
      _verifyOtp();
    }
  }
  
  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final local = parts[0];
    final domain = parts[1];
    if (local.length <= 2) return widget.email;
    return '${local.substring(0, 2)}${'•' * (local.length - 2)}@$domain';
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () => context.pop(),
                  ),
                ),
                
                const Spacer(),
                
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Введите код',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Код отправлен на $_maskedEmail',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      AppConstants.otpLength,
                      (index) => SizedBox(
                        width: 56,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.backspace &&
                                _controllers[index].text.isEmpty &&
                                index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              filled: true,
                              fillColor: _controllers[index].text.isNotEmpty
                                  ? AppColors.primary.withAlpha(51)
                                  : AppColors.surface,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onCodeChanged(index, value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authState.error!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: _resendSeconds == 0 ? _resendCode : null,
                  child: Text(
                    _resendSeconds > 0
                        ? 'Отправить повторно через $_resendSeconds сек'
                        : 'Отправить повторно',
                    style: TextStyle(
                      color: _resendSeconds > 0
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                PrimaryButton(
                  text: 'Подтвердить',
                  isLoading: authState.isLoading,
                  onPressed: _code.length == AppConstants.otpLength ? _verifyOtp : null,
                  width: double.infinity,
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
