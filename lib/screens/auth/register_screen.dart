import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../repositories/auth_repository.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  final location = TextEditingController();
  bool hide = true;
  bool loading = false;

  @override
  void dispose() {
    for (final controller in [name, email, phone, pass, confirm, location]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      await AuthRepository().register(
        name: name.text,
        email: email.text,
        phone: phone.text,
        location: location.text,
        password: pass.text,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthRepository.messageFor(error))),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: form,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your name',
                      controller: name,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Please enter your name'
                              : null,
                    ),
                    CustomTextField(
                      label: 'Email',
                      hint: 'Enter email',
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Please enter a valid email'
                              : null,
                    ),
                    CustomTextField(
                      label: 'Phone',
                      hint: 'Enter phone number',
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().length < 10
                              ? 'Please enter a valid phone'
                              : null,
                    ),
                    CustomTextField(
                      label: 'Password',
                      hint: 'At least 6 characters',
                      controller: pass,
                      obscureText: hide,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hide = !hide),
                        icon: Icon(
                          hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    CustomTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter password',
                      controller: confirm,
                      obscureText: true,
                      validator: (value) =>
                          value != pass.text ? 'Passwords do not match' : null,
                    ),
                    CustomTextField(
                      label: 'Location',
                      hint: 'City / area',
                      controller: location,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: loading ? 'Creating account...' : 'Create Account',
                      onPressed: loading ? null : submit,
                      loading: loading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
