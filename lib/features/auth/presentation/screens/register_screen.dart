import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:savesmart/controllers/auth_controller.dart';
import 'package:savesmart/routing/app_router.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _nameFocus    = FocusNode();
  final _emailFocus   = FocusNode();
  final _passFocus    = FocusNode();
  final _confirmFocus = FocusNode();
  final _auth         = Get.find<AuthController>();

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    _nameFocus.dispose(); _emailFocus.dispose();
    _passFocus.dispose(); _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await _auth.register(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!ok && mounted) {
      Get.snackbar('Error', _auth.errorMessage.value ?? 'Registration failed.',
          backgroundColor: Theme.of(context).colorScheme.error,
          colorText: Theme.of(context).colorScheme.onError);
    } else if (ok) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme   = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => Get.back()),
          backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account', style: textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text('Start your savings journey today',
                    style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),

                Obx(() => AuthTextField(
                  controller: _nameCtrl, label: 'Full Name',
                  hint: 'Abebe Kebede',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  focusNode: _nameFocus, nextFocusNode: _emailFocus,
                  enabled: !_auth.isLoading.value,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Your name is required.';
                    if (v.trim().length < 2) return 'Name is too short.';
                    return null;
                  },
                )),
                const SizedBox(height: 16),

                Obx(() => AuthTextField(
                  controller: _emailCtrl, label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus, nextFocusNode: _passFocus,
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

                Obx(() => AuthTextField(
                  controller: _passCtrl, label: 'Password',
                  obscure: true, prefixIcon: Icons.lock_outlined,
                  textInputAction: TextInputAction.next,
                  focusNode: _passFocus, nextFocusNode: _confirmFocus,
                  enabled: !_auth.isLoading.value,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required.';
                    if (v.length < 6) return 'Must be at least 6 characters.';
                    return null;
                  },
                )),
                const SizedBox(height: 16),

                Obx(() => AuthTextField(
                  controller: _confirmCtrl, label: 'Confirm Password',
                  obscure: true, prefixIcon: Icons.lock_outlined,
                  textInputAction: TextInputAction.done,
                  focusNode: _confirmFocus,
                  enabled: !_auth.isLoading.value,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password.';
                    if (v != _passCtrl.text) return 'Passwords do not match.';
                    return null;
                  },
                )),
                const SizedBox(height: 28),

                Obx(() => PrimaryButton(
                  label: 'Create Account', onPressed: _submit,
                  isLoading: _auth.isLoading.value,
                  icon: Icons.person_add_rounded,
                )),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: textTheme.bodyMedium),
                    TextButton(onPressed: () => Get.back(),
                        child: const Text('Log In')),
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
