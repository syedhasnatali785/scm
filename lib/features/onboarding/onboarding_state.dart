import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/organization.dart';
import '../../core/services/cookie_service.dart';
import '../../data/repositories/organization_repository.dart';
import '../auth/auth_state.dart';

@immutable
class OrganizationProfile {
  final String orgId;
  final String orgName;
  final String baseCurrency; // Default 'PKR'
  final String defaultOriginCurrency; // Default 'RMB'
  final String workflowPreset; // 'Finished Goods' or 'SKD Assembly'
  final bool isOnboarded;

  const OrganizationProfile({
    this.orgId = '02337732-6c78-496b-bd95-f10feef8e135',
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
      defaultOriginCurrency:
          defaultOriginCurrency ?? this.defaultOriginCurrency,
      workflowPreset: workflowPreset ?? this.workflowPreset,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OrganizationProfile> {
  final IOrganizationRepository _repository;
  final Ref? _ref;

  OnboardingNotifier(this._repository, [this._ref])
      : super(const OrganizationProfile());

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

  Future<Organization?> completeOnboarding({String? userId}) async {
    state = state.copyWith(isOnboarded: true);
    try {
      final orgId = const Uuid().v4();
      final slug = state.orgName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-');

      final effectiveUserId = userId ?? _ref?.read(authProvider).value?.id;

      final org = Organization(
        id: orgId,
        name: state.orgName.trim().isNotEmpty
            ? state.orgName.trim()
            : '71 International Trading',
        slug: slug.isNotEmpty ? slug : 'org-$orgId',
        baseCurrency: state.baseCurrency,
        defaultOriginCurrency: state.defaultOriginCurrency,
        workflowPreset: state.workflowPreset,
      );

      final created =
          await _repository.createOrganization(org, userId: effectiveUserId);
      state = state.copyWith(
        orgId: created.id,
        orgName: created.name,
        isOnboarded: true,
      );

      // Persist active organization cookie
      CookieService.setCookie('active_org_id', created.id, maxAgeDays: 30);

      // Add to auth state so active tenant is instantly reactive
      if (_ref != null) {
        try {
          _ref.read(authProvider.notifier).addOrganization(created);
        } catch (_) {}
      }

      return created;
    } catch (e) {
      debugPrint('Error saving organization to Supabase: $e');
      return null;
    }
  }
}

final organizationRepositoryProvider =
    Provider<IOrganizationRepository>((ref) {
  return SupabaseOrganizationRepository();
});

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OrganizationProfile>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return OnboardingNotifier(repo, ref);
});

typedef OnboardingViewModel = OnboardingNotifier;
