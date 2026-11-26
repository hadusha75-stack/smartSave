import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _auth      = Get.find<AuthController>();

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await _auth.sendPasswordReset(_emailCtrl.text);

    if (!mounted) return;
    if (ok) {
      Get.snackbar('Email sent',
          'Password reset email sent. Check your inbox.',
          backgroundColor: Theme.of(context).colorScheme.primary,
          colorText: Theme.of(context).colorScheme.onPrimary,
          duration: const Duration(seconds: 4));
      await Future.delayed(const Duration(seconds: 2));
      Get.back();
    } else {
      Get.snackbar('Error', _auth.errorMessage.value ?? 'Failed to send.',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Get.back()),
          backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.lock_reset_rounded, size: 36,
                      color: colorScheme.onSecondaryContainer),
                ),
                const SizedBox(height: 20),
                Text('Reset Password', style: textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text("Enter your registered email and we'll send a reset link.",
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),

                Obx(() => AuthTextField(
                  controller: _emailCtrl, label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.done,
                  enabled: !_auth.isLoading.value,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required.';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                )),
                const SizedBox(height: 28),

                Obx(() => PrimaryButton(
                  label: 'Send Reset Link', onPressed: _submit,
                  isLoading: _auth.isLoading.value,
                  icon: Icons.send_rounded,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
