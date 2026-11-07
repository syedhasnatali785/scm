import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_state.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController(
    text: 'owner@71international.com',
  );
  final TextEditingController _passwordCtrl = TextEditingController(
    text: 'password123',
  );
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) return;

    if (_isSignUp) {
      await ref
          .read(authProvider.notifier)
          .signUpZeroOtp(email, pass, _nameCtrl.text.trim());
    } else {
      await ref
          .read(authProvider.notifier)
          .signInWithEmailPassword(email, pass);
    }

    final authState = ref.read(authProvider);
    if (authState.hasValue && authState.value != null && mounted) {
      final user = authState.value!;
      final hasOrg =
          user.activeOrganization != null || user.organizations.isNotEmpty;
      if (hasOrg) {
        context.go('/command-center');
      } else {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _loginGoogle() async {
    await ref.read(authProvider.notifier).signInWithGoogle();
    final authState = ref.read(authProvider);
    if (authState.hasValue && authState.value != null && mounted) {
      final user = authState.value!;
      final hasOrg =
          user.activeOrganization != null || user.organizations.isNotEmpty;
      if (hasOrg) {
        context.go('/command-center');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF131D38),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF223154)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '71 INTERNATIONAL',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Supply Chain Management System',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign In / Sign Up Mode Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _isSignUp = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !_isSignUp
                                  ? const Color(0xFF0284C7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: !_isSignUp
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _isSignUp = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSignUp
                                  ? const Color(0xFF0284C7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Zero-OTP Sign Up',
                              style: TextStyle(
                                color: _isSignUp
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                // Zero-OTP Cookie Persistence Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.cookie_outlined,
                        size: 14,
                        color: Color(0xFF34D399),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Form Fields
                if (_isSignUp) ...[
                  TextField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Work Email Address',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Remember Me Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Remember this device with secure cookies',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                if (authState.hasError) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFF87171),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error.toString().replaceAll(
                              'Exception: ',
                              '',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Create Company Account' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Demo Accounts Chips
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSignUp = false;
                          _emailCtrl.text = '';
                          _passwordCtrl.text = '';
                        });
                      },
                      icon: const Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: Color(0xFF38BDF8),
                      ),
                      label: const Text(
                        'Owner Login',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isSignUp = false;
                          _emailCtrl.text = 'operator@71international.com';
                          _passwordCtrl.text = 'password123';
                        });
                      },
                      icon: const Icon(
                        Icons.badge_outlined,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      label: const Text(
                        'Operator Login',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF223154))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFF223154))),
                  ],
                ),
                const SizedBox(height: 14),

                // Google OAuth Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 28,
                      color: Color(0xFF38BDF8),
                    ),
                    label: const Text(
                      'Continue with Google Workspace',
                      style: TextStyle(fontSize: 13),
                    ),
                    onPressed: isLoading ? null : _loginGoogle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
