import 'package:flutter/foundation.dart';
import '../../core/models/organization.dart';
import '../../core/network/supabase_config.dart';

abstract class IOrganizationRepository {
  Future<List<Organization>> getOrganizations();
  Future<Organization?> getOrganizationById(String id);
  Future<Organization> createOrganization(Organization org, {String? userId});
  Future<void> updateOrganization(Organization org);
}

class SupabaseOrganizationRepository implements IOrganizationRepository {
  Organization _cachedOrg = const Organization(
    id: 'org_default_71',
    name: '71 International Trading',
    slug: '71-international',
    baseCurrency: 'PKR',
    defaultOriginCurrency: 'RMB',
    workflowPreset: 'SKD Assembly',
  );

  bool get _canUseSupabase =>
      SupabaseConfig.isInitialized && !SupabaseConfig.isMockMode;

  @override
  Future<List<Organization>> getOrganizations() async {
    if (_canUseSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from('organizations')
            .select()
            .order('created_at', ascending: true);
        final list = (res as List)
            .map((e) => Organization.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) {
          _cachedOrg = list.first;
        }
        return list;
      } catch (e) {
        debugPrint('Supabase getOrganizations error: $e');
      }
    }
    return [_cachedOrg];
  }

  @override
  Future<Organization?> getOrganizationById(String id) async {
    if (_canUseSupabase) {
      try {
        final res = await SupabaseConfig.client
            .from('organizations')
            .select()
            .eq('id', id)
            .maybeSingle();
        if (res != null) {
          final org = Organization.fromMap(Map<String, dynamic>.from(res));
          _cachedOrg = org;
          return org;
        }
      } catch (e) {
        debugPrint('Supabase getOrganizationById error: $e');
      }
    }
    return _cachedOrg.id == id ? _cachedOrg : null;
  }

  @override
  Future<Organization> createOrganization(Organization org, {String? userId}) async {
    _cachedOrg = org;
    if (_canUseSupabase) {
      try {
        final map = org.toMap();
        final res = await SupabaseConfig.client
            .from('organizations')
            .insert(map)
            .select()
            .single();
        final created = Organization.fromMap(Map<String, dynamic>.from(res));
        _cachedOrg = created;

        // If user is authenticated, create org membership
        final uid = userId ?? SupabaseConfig.client.auth.currentUser?.id;
        if (uid != null) {
          await SupabaseConfig.client.from('org_memberships').insert({
            'org_id': created.id,
            'user_id': uid,
            'role': 'owner',
          });
        }
        return created;
      } catch (e) {
        debugPrint('Supabase createOrganization error: $e');
      }
    }
    return org;
  }

  @override
  Future<void> updateOrganization(Organization org) async {
    _cachedOrg = org;
    if (_canUseSupabase) {
      try {
        await SupabaseConfig.client
            .from('organizations')
            .update(org.toMap())
            .eq('id', org.id);
      } catch (e) {
        debugPrint('Supabase updateOrganization error: $e');
      }
    }
  }
}

