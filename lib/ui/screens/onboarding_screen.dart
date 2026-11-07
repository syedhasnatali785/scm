import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final TextEditingController _orgNameCtrl = TextEditingController(text: '71 International Trading');

  final List<String> _baseCurrencies = ['PKR', 'AED', 'SAR', 'USD', 'GBP', 'EUR'];
  final List<String> _originCurrencies = ['RMB', 'USD', 'EUR', 'JPY', 'INR'];

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Complete Onboarding
      ref.read(onboardingProvider.notifier).setOrgName(_orgNameCtrl.text.trim());
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (mounted) {
        context.go('/command-center');
      }
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 650,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: const Color(0xFF131D38),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF223154)),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand & Step Indicator
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF38BDF8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '71 INTERNATIONAL // SETUP WIZARD',
                          style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 3',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Step Progress Bar
                Row(
                  children: List.generate(3, (index) {
                    final isDone = index <= _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Step Contents
                if (_currentStep == 0) _buildStep1(profile),
                if (_currentStep == 1) _buildStep2(profile),
                if (_currentStep == 2) _buildStep3(profile),

                const SizedBox(height: 32),

                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back'),
                        onPressed: _prev,
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: Icon(_currentStep == 2 ? Icons.check_circle_outline : Icons.arrow_forward, size: 18),
                      label: Text(
                        _currentStep == 2 ? 'Launch Command Center' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _next,
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

  Widget _buildStep1(OrganizationProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workspace & Base Currency',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Define your organization name and destination accounting currency. All import duties, local transport, and unit landed profits will be computed in this currency.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _orgNameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Company / Organization Name',
            labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF38BDF8), size: 20),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'DESTINATION BASE CURRENCY:',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _baseCurrencies.map((c) {
            final isSelected = profile.baseCurrency == c;
            return ChoiceChip(
              label: Text(c == 'PKR' ? 'PKR ₨ (Default Pakistan)' : c),
              selected: isSelected,
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => ref.read(onboardingProvider.notifier).setBaseCurrency(c),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep2(OrganizationProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Default Sourcing Origin Currency',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select the primary currency your overseas factories quote in (e.g. Chinese Yuan RMB or US Dollar USD). The live FX engine will continuously sync this rate to your base currency.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _originCurrencies.map((c) {
            final isSelected = profile.defaultOriginCurrency == c;
            String desc = '';
            if (c == 'RMB') desc = '¥ Chinese Yuan (Standard China Factory Quotes)';
            if (c == 'USD') desc = '\$ US Dollar (International Ocean & Air)';
            if (c == 'EUR') desc = '€ Euro (European Sourcing)';
            if (c == 'JPY') desc = '¥ Japanese Yen';
            if (c == 'INR') desc = '₹ Indian Rupee';

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => ref.read(onboardingProvider.notifier).setDefaultOriginCurrency(c),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.2) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: c,
                      groupValue: profile.defaultOriginCurrency,
                      activeColor: const Color(0xFF38BDF8),
                      onChanged: (val) {
                        if (val != null) ref.read(onboardingProvider.notifier).setDefaultOriginCurrency(val);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3(OrganizationProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational Workflow Preset',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose how your goods arrive at the destination warehouse. You can always override this on individual product items anytime.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        _workflowCard(
          title: 'SKD / CKD Assembly Mode',
          subtitle: 'Products arrive in parts/knocked-down and require local corrugated packaging, technician labor, batteries/chargers, and defect wastage buffers.',
          badge: 'RECOMMENDED FOR TOYS, APPLIANCES & BIKES',
          icon: Icons.build_circle_rounded,
          isSelected: profile.workflowPreset == 'SKD Assembly',
          onTap: () => ref.read(onboardingProvider.notifier).setWorkflowPreset('SKD Assembly'),
        ),
        const SizedBox(height: 14),
        _workflowCard(
          title: 'Finished Goods Mode',
          subtitle: 'Products arrive fully packaged and retail-ready straight from the container without local value-addition or assembly steps.',
          badge: 'FOR RETAIL-READY CONSUMER GOODS',
          icon: Icons.inventory_2_rounded,
          isSelected: profile.workflowPreset == 'Finished Goods',
          onTap: () => ref.read(onboardingProvider.notifier).setWorkflowPreset('Finished Goods'),
        ),
      ],
    );
  }

  Widget _workflowCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7).withValues(alpha: 0.18) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

