import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/routing/app_router.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _emailFocus  = FocusNode();
  final _passFocus   = FocusNode();
  final _auth        = Get.find<AuthController>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await _auth.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!ok && mounted) {
      Get.snackbar(
        'Error',
        _auth.errorMessage.value ?? 'Login failed.',
        backgroundColor: Theme.of(context).colorScheme.error,
        colorText: Theme.of(context).colorScheme.onError,
      );
    } else if (ok) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme   = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: AuthLogo()),
                const SizedBox(height: 40),
                Text('Welcome back', style: textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Log in to continue saving',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),

                // Email
                Obx(() => AuthTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  nextFocusNode: _passFocus,
                  enabled: !_auth.isLoading.value,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required.';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                )),
                const SizedBox(height: 16),

                // Password
                Obx(() => AuthTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  obscure: true,
                  prefixIcon: Icons.lock_outlined,
                  textInputAction: TextInputAction.done,
                  focusNode: _passFocus,
                  enabled: !_auth.isLoading.value,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required.';
                    if (v.length < 6) return 'Must be at least 6 characters.';
                    return null;
                  },
                )),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.forgotPass),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit
                Obx(() => PrimaryButton(
                  label: 'Log In',
                  onPressed: _submit,
                  isLoading: _auth.isLoading.value,
                  icon: Icons.login_rounded,
                )),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.register),
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
