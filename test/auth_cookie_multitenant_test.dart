import 'package:flutter_test/flutter_test.dart';
import 'package:scm/core/models/organization.dart';
import 'package:scm/core/services/cookie_service.dart';
import 'package:scm/features/auth/auth_state.dart';

void main() {
  group('Multi-Tenant Cookie & Persistent Auth Tests', () {
    setUp(() {
      CookieService.removeCookie('sb-session');
      CookieService.removeCookie('sb-user-id');
      CookieService.removeCookie('sb-user-email');
      CookieService.removeCookie('active_org_id');
    });

    test('CookieService stores, retrieves, and purges cookies accurately', () {
      CookieService.setCookie('test_cookie', 'sample_val_123', maxAgeDays: 30);
      expect(CookieService.getCookie('test_cookie'), 'sample_val_123');

      CookieService.removeCookie('test_cookie');
      expect(CookieService.getCookie('test_cookie'), isNull);
    });

    test('AppUser holds multiple tenant organizations and active organization', () {
      const orgA = Organization(
        id: 'org_001',
        name: 'Alpha Logistics',
        slug: 'alpha-logistics',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
      );
      const orgB = Organization(
        id: 'org_002',
        name: 'Beta Global Trade',
        slug: 'beta-global',
        baseCurrency: 'AED',
        defaultOriginCurrency: 'USD',
      );

      final user = AppUser(
        id: 'usr_test_1',
        email: 'ceo@alphalogistics.com',
        name: 'CEO',
        role: 'owner',
        organizations: const [orgA, orgB],
        activeOrganization: orgA,
      );

      expect(user.organizations.length, 2);
      expect(user.activeOrganization?.id, 'org_001');

      final switched = user.copyWith(activeOrganization: orgB);
      expect(switched.activeOrganization?.id, 'org_002');
      expect(switched.activeOrganization?.baseCurrency, 'AED');
    });

    test('AuthNotifier handles offline login, cookie sync, and tenant switching', () async {
      final auth = AuthNotifier();

      // Sign in offline
      await auth.signInWithEmailPassword('founder@71international.com', 'pass123');

      final user = auth.state.value;
      expect(user, isNotNull);
      expect(user?.email, 'founder@71international.com');

      // Add primary organization
      const firstOrg = Organization(
        id: 'org_primary_71',
        name: '71 International Trading',
        slug: '71-international',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
      );
      auth.addOrganization(firstOrg);

      // Add a second organization
      const secondOrg = Organization(
        id: 'org_secondary_71',
        name: '71 China Sourcing Branch',
        slug: '71-china-sourcing',
        baseCurrency: 'PKR',
        defaultOriginCurrency: 'RMB',
      );
      auth.addOrganization(secondOrg);

      expect(auth.state.value?.organizations.length, 2);
      expect(auth.state.value?.activeOrganization?.id, 'org_secondary_71');
      expect(CookieService.getCookie('active_org_id'), 'org_secondary_71');

      // Switch back to primary
      final firstOrgId = auth.state.value!.organizations.first.id;
      auth.switchOrganization(firstOrgId);
      expect(auth.state.value?.activeOrganization?.id, firstOrgId);
      expect(CookieService.getCookie('active_org_id'), firstOrgId);

      // Sign out purges cookies
      await auth.signOut();
      expect(auth.state.value, isNull);
      expect(CookieService.getCookie('active_org_id'), isNull);
    });
  });
}
