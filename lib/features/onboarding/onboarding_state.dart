import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/organization.dart';
import '../../data/repositories/organization_repository.dart';

@immutable
class OrganizationProfile {
  final String orgId;
  final String orgName;
  final String baseCurrency;       // Default 'PKR'
  final String defaultOriginCurrency; // Default 'RMB'
  final String workflowPreset;     // 'Finished Goods' or 'SKD Assembly'
  final bool isOnboarded;

  const OrganizationProfile({
    this.orgId = 'org_default_71',
    this.orgName = '71 International Trading',
    this.baseCurrency = 'PKR',
    this.defaultOriginCurrency = 'RMB',
    this.workflowPreset = 'SKD Assembly',
    this.isOnboarded = false,
  });

  OrganizationProfile copyWith({
    String? orgId,
    String? orgName,
    String? baseCurrency,
    String? defaultOriginCurrency,
    String? workflowPreset,
    bool? isOnboarded,
  }) {
    return OrganizationProfile(
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      defaultOriginCurrency: defaultOriginCurrency ?? this.defaultOriginCurrency,
      workflowPreset: workflowPreset ?? this.workflowPreset,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OrganizationProfile> {
  final IOrganizationRepository _repository;

  OnboardingNotifier(this._repository) : super(const OrganizationProfile());

  void setOrgName(String name) {
    state = state.copyWith(orgName: name);
  }

  void setBaseCurrency(String currency) {
    state = state.copyWith(baseCurrency: currency);
  }

  void setDefaultOriginCurrency(String currency) {
    state = state.copyWith(defaultOriginCurrency: currency);
  }

  void setWorkflowPreset(String preset) {
    state = state.copyWith(workflowPreset: preset);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isOnboarded: true);
    try {
      final slug = state.orgName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      final org = Organization(
        id: 'org_${DateTime.now().millisecondsSinceEpoch}',
        name: state.orgName,
        slug: slug.isNotEmpty ? slug : 'org-tenant',
        baseCurrency: state.baseCurrency,
        defaultOriginCurrency: state.defaultOriginCurrency,
        workflowPreset: state.workflowPreset,
      );
      final created = await _repository.createOrganization(org);
      state = state.copyWith(orgId: created.id);
    } catch (e) {
      debugPrint('Error saving organization to Supabase: $e');
    }
  }
}

final organizationRepositoryProvider = Provider<IOrganizationRepository>((ref) {
  return SupabaseOrganizationRepository();
});

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OrganizationProfile>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return OnboardingNotifier(repo);
});

typedef OnboardingViewModel = OnboardingNotifier;


