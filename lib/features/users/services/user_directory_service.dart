import '../models/system_user.dart';
import '../../auth/models/user_role.dart';

class UserDirectoryService {
  static final List<SystemUser> _users = [
    // ====== Admin / Direction / IT ======
    const SystemUser(
      matricule: 'ADMIN001',
      fullName: 'Administrateur Système',
      role: UserRole.admin,
      site: 'Siège',
      city: 'Kinshasa',
      phone: '+243000000001',
      active: true,
    ),
    const SystemUser(
      matricule: 'IT001',
      fullName: 'Mukendi Junior',
      role: UserRole.user,
      site: 'Siège',
      city: 'Kinshasa',
      phone: '+243000000002',
      active: true,
    ),
    const SystemUser(
      matricule: 'IT002',
      fullName: 'Mbuyi Grace',
      role: UserRole.user,
      site: 'Siège',
      city: 'Kinshasa',
      phone: '+243000000003',
      active: true,
    ),

    // ====== Project Managers ======
    const SystemUser(
      matricule: 'PM001',
      fullName: 'Kabasele Patrick',
      role: UserRole.projectManager,
      site: 'KCC',
      city: 'Kolwezi',
      phone: '+243000001001',
      active: true,
    ),
    const SystemUser(
      matricule: 'PM002',
      fullName: 'Tshibangu Nadine',
      role: UserRole.projectManager,
      site: 'Tenke',
      city: 'Likasi',
      phone: '+243000001002',
      active: true,
    ),
    const SystemUser(
      matricule: 'PM003',
      fullName: 'Kasongo Alain',
      role: UserRole.projectManager,
      site: 'Kamoa',
      city: 'Kolwezi',
      phone: '+243000001003',
      active: true,
    ),
    const SystemUser(
      matricule: 'PM004',
      fullName: 'Ilunga Esther',
      role: UserRole.projectManager,
      site: 'Lubumbashi Hub',
      city: 'Lubumbashi',
      phone: '+243000001004',
      active: true,
    ),

    // ====== Supervisors ======
    const SystemUser(
      matricule: 'SUP001',
      fullName: 'Mwamba Roger',
      role: UserRole.supervisor,
      site: 'KCC',
      city: 'Kolwezi',
      phone: '+243000002001',
      active: true,
    ),
    const SystemUser(
      matricule: 'SUP002',
      fullName: 'Kanyembo Chantal',
      role: UserRole.supervisor,
      site: 'Tenke',
      city: 'Likasi',
      phone: '+243000002002',
      active: true,
    ),
    const SystemUser(
      matricule: 'SUP003',
      fullName: 'Kashala David',
      role: UserRole.supervisor,
      site: 'Kamoa',
      city: 'Kolwezi',
      phone: '+243000002003',
      active: true,
    ),
    const SystemUser(
      matricule: 'SUP004',
      fullName: 'Kabongo Mireille',
      role: UserRole.supervisor,
      site: 'Lubumbashi Hub',
      city: 'Lubumbashi',
      phone: '+243000002004',
      active: true,
    ),
    const SystemUser(
      matricule: 'SUP005',
      fullName: 'Nsenga Moïse',
      role: UserRole.supervisor,
      site: 'Fungurume',
      city: 'Fungurume',
      phone: '+243000002005',
      active: true,
    ),

    // ====== Users (techniciens / terrain / admin) ======
    const SystemUser(
      matricule: 'USR001',
      fullName: 'Utilisateur Test',
      role: UserRole.user,
      site: 'Site A',
      city: 'Lubumbashi',
      phone: '+243000003001',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC014',
      fullName: 'Kalala Daniel',
      role: UserRole.user,
      site: 'KCC',
      city: 'Kolwezi',
      phone: '+243000003014',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC107',
      fullName: 'Munga Rebecca',
      role: UserRole.user,
      site: 'KCC',
      city: 'Kolwezi',
      phone: '+243000003107',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC021',
      fullName: 'Katongo Fabrice',
      role: UserRole.user,
      site: 'Tenke',
      city: 'Likasi',
      phone: '+243000003021',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC033',
      fullName: 'Songa Prisca',
      role: UserRole.user,
      site: 'Tenke',
      city: 'Likasi',
      phone: '+243000003033',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC045',
      fullName: 'Kanku Steve',
      role: UserRole.user,
      site: 'Kamoa',
      city: 'Kolwezi',
      phone: '+243000003045',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC052',
      fullName: 'Mpoyi Diane',
      role: UserRole.user,
      site: 'Kamoa',
      city: 'Kolwezi',
      phone: '+243000003052',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC060',
      fullName: 'Lukusa Joël',
      role: UserRole.user,
      site: 'Lubumbashi Hub',
      city: 'Lubumbashi',
      phone: '+243000003060',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC061',
      fullName: 'Banza Carine',
      role: UserRole.user,
      site: 'Lubumbashi Hub',
      city: 'Lubumbashi',
      phone: '+243000003061',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC070',
      fullName: 'Mukeba Armand',
      role: UserRole.user,
      site: 'Fungurume',
      city: 'Fungurume',
      phone: '+243000003070',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC072',
      fullName: 'Ntumba Sarah',
      role: UserRole.user,
      site: 'Fungurume',
      city: 'Fungurume',
      phone: '+243000003072',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC080',
      fullName: 'Kafwimbi Jonas',
      role: UserRole.user,
      site: 'Kipushi',
      city: 'Lubumbashi',
      phone: '+243000003080',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC081',
      fullName: 'Kalombo Mireille',
      role: UserRole.user,
      site: 'Kipushi',
      city: 'Lubumbashi',
      phone: '+243000003081',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC090',
      fullName: 'Kabeya Thierry',
      role: UserRole.user,
      site: 'Kamina',
      city: 'Kamina',
      phone: '+243000003090',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC091',
      fullName: 'Ndaya Floriane',
      role: UserRole.user,
      site: 'Kamina',
      city: 'Kamina',
      phone: '+243000003091',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC100',
      fullName: 'Kanku Didier',
      role: UserRole.user,
      site: 'Kolwezi Base',
      city: 'Kolwezi',
      phone: '+243000003100',
      active: true,
    ),
    const SystemUser(
      matricule: 'MRC101',
      fullName: 'Kanyinda Aline',
      role: UserRole.user,
      site: 'Kolwezi Base',
      city: 'Kolwezi',
      phone: '+243000003101',
      active: true,
    ),

    // Inactifs (pour tester validation)
    const SystemUser(
      matricule: 'MRC999',
      fullName: 'Ancien Agent',
      role: UserRole.user,
      site: 'Siège',
      city: 'Kinshasa',
      phone: '+243000009999',
      active: false,
    ),
  ];

  static List<SystemUser> getAll({bool activeOnly = true}) {
    if (!activeOnly) return List.unmodifiable(_users);
    return List.unmodifiable(_users.where((u) => u.active).toList());
  }

  static List<SystemUser> search(String query, {bool activeOnly = true}) {
    final list = getAll(activeOnly: activeOnly);
    return list.where((u) => u.matchesQuery(query)).toList();
  }

  static bool exists(String matricule, {bool activeOnly = true}) {
    final m = matricule.trim();
    if (m.isEmpty) return false;
    final list = getAll(activeOnly: activeOnly);
    return list.any((u) => u.matricule == m);
  }

  static SystemUser? findByMatricule(String matricule, {bool activeOnly = true}) {
    final m = matricule.trim();
    if (m.isEmpty) return null;
    final list = getAll(activeOnly: activeOnly);
    try {
      return list.firstWhere((u) => u.matricule == m);
    } catch (_) {
      return null;
    }
  }
}
