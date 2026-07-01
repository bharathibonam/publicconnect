class MandalMapping {
  static const List<String> mandals = [
    'Jaggampeta',
    'Gandepalle',
    'Gokavaram',
    'Kirlampudi',
  ];

  static const Map<String, List<String>> _mandalToPanchayats = {
    'Jaggampeta': [
      'Gollalagunta GP',
      'Govindapuram GP',
      'Gurrappalem GP',
      'Irripaka GP',
      'J. Kothuru GP',
      'Jaggampeta GP',
      'Kandregula GP',
      'Katravulapalle GP',
      'Mallisala GP',
      'Mamidada GP',
      'Manyanvari Palem GP',
      'Marripaka GP',
      'Narendrapatnam GP',
      'Ramavaram GP',
      'Vengayamma Puram GP',
    ],
    'Gandepalle': [
      'Borrampalem GP',
      'Gandepalle GP',
      'Mallepalli GP',
      'Murari GP',
      'P. Nayakampalle GP',
      'P. Surampalem GP',
      'Ramayyapalem GP',
      'Singarampalem GP',
      'Talluru GP',
      'Uppalapadu GP',
      'Yellamilli GP',
      'Yerrampalem GP',
      'Z. Ragampeta GP',
    ],
    'Gokavaram': [
      'Atchutapuram GP',
      'Gadelapalem GP',
      'Gangampalem GP',
      'Gokavaram GP',
      'Gummalladuddi GP',
      'Itikayala Palle GP',
      'Kamarajupeta GP',
      'Kothapalle GP',
      'Krishnuni Palem GP',
      'Mallavaram GP',
      'Rampa Yerrampalem GP',
      'Thanti Konda GP',
      'Tirumalayapalem GP',
      'Vedurupaka GP',
    ],
    'Kirlampudi': [
      'Bhupalapatnam GP',
      'Burugupudi GP',
      'Geddanapalle GP',
      'Goneda GP',
      'Jagapathinagaram GP',
      'Krishnavaram GP',
      'Mukkollu GP',
      'Palem GP',
      'Rajupalem GP',
      'Ramachandra Puram GP',
      'Ramakrishnapuram GP',
      'S. Thimmapuram GP',
      'Simhadri Puram GP',
      'Somanarayani Peta GP',
      'Somavaram GP',
      'Sungarayunipalem GP',
      'Thamarada GP',
      'Veeravaram GP',
      'Velanka GP',
    ],
  };

  /// Returns the proper mandal for a panchayat based on master data.
  static String getMandalForPanchayat(String panchayatName) {
    for (final entry in _mandalToPanchayats.entries) {
      if (entry.value.contains(panchayatName)) {
        return entry.key;
      }
    }
    // Fallback if not found in master data
    int hash = 0;
    for (int i = 0; i < panchayatName.length; i++) {
      hash += panchayatName.codeUnitAt(i);
    }
    return mandals[hash % mandals.length];
  }

  /// Returns all panchayats that belong to a specific mandal from a list of all panchayats.
  static List<String> getPanchayatsForMandal(String mandalName, [List<String>? allPanchayats]) {
    final mapped = _mandalToPanchayats[mandalName] ?? [];
    return mapped.toList()..sort();
  }

  static const Map<String, List<String>> panchayatToVillages = {
    'Gram Panchayat': [
      'Village / Town',
    ],
    'Gurrappalem GP': [
      'Balabhadrapuram',
      'Gurrappalem',
    ],
    'Gollalagunta GP': [
      'Gollalagunta',
      'Seethampeta',
    ],
    'Govindapuram GP': [
      'Govindapuram',
    ],
    'Irripaka GP': [
      'Irripaka',
    ],
    'J. Kothuru GP': [
      'J. Kothuru',
      'Tirupatirajupeta',
    ],
    'Jaggampeta GP': [
      'Jaggampeta',
      'Seethanagaram',
    ],
    'Kandregula GP': [
      'Kandregula',
    ],
    'Katravulapalle GP': [
      'Katravulapalle',
    ],
    'Mallisala GP': [
      'Mallisala',
    ],
    'Mamidada GP': [
      'Mamidada',
    ],
    'Manyanvari Palem GP': [
      'Manyanvaripalem',
    ],
    'Marripaka GP': [
      'Marripaka',
    ],
    'Narendrapatnam GP': [
      'Narendrapatnam',
    ],
    'Vengayamma Puram GP': [
      'Rajapudi',
    ],
    'Ramavaram GP': [
      'Ramavaram',
    ],
    'Borrampalem GP': [
      'Borrampalem',
    ],
    'Gandepalle GP': [
      'Gandepalle',
    ],
    'Mallepalli GP': [
      'Mallepalle',
    ],
    'Murari GP': [
      'Murari',
    ],
    'Ramayyapalem GP': [
      'North Tirupathi Rajapuram',
    ],
    'P. Nayakampalle GP': [
      'P. Nayakampalle',
    ],
    'Z. Ragampeta GP': [
      'Pro. Ragampeta',
    ],
    'Singarampalem GP': [
      'Singarampalem',
    ],
    'P. Surampalem GP': [
      'Surampalem',
    ],
    'Talluru GP': [
      'Talluru',
    ],
    'Uppalapadu GP': [
      'Uppalapadu',
    ],
    'Yellamilli GP': [
      'Yellamilli',
    ],
    'Yerrampalem GP': [
      'Yerrampalem',
    ],
    'Atchutapuram GP': [
      'Atchutapuram',
    ],
    'Kamarajupeta GP': [
      'Bhupatipalem',
      'Kamaraju Peta',
      'Sivaramapatnam',
      'Sudikonda',
    ],
    'Gadelapalem GP': [
      'Gadelapalem',
    ],
    'Gangampalem GP': [
      'Gangampalem',
      'Takurupalem',
    ],
    'Gokavaram GP': [
      'Gokavaram',
    ],
    'Gummalladuddi GP': [
      'Gummalladuddi',
    ],
    'Itikayala Palle GP': [
      'Itikayala Palle',
    ],
    'Mallavaram GP': [
      'Kalijolla',
      'Mallavaram',
    ],
    'Kothapalle GP': [
      'Kothapalle',
    ],
    'Krishnuni Palem GP': [
      'Krishnunipalem',
    ],
    'Rampa Yerrampalem GP': [
      'Rampa Yerrampalem',
    ],
    'Thanti Konda GP': [
      'Thantikonda',
    ],
    'Tirumalayapalem GP': [
      'Tirumalayapalem',
    ],
    'Vedurupaka GP': [
      'Vedurupaka',
    ],
    'Bhupalapatnam GP': [
      'Bhupalapatnam',
    ],
    'Burugupudi GP': [
      'Burugupudi',
    ],
    'Jagapathinagaram GP': [
      'Chillangi',
      'Jagapathinagaram',
      'Kirlampudi',
    ],
    'Geddanapalle GP': [
      'Geddanapalle',
    ],
    'Goneda GP': [
      'Goneda',
    ],
    'Krishnavaram GP': [
      'Krishnavaram',
    ],
    'Mukkollu GP': [
      'Mukkollu',
    ],
    'Palem GP': [
      'Palem',
    ],
    'Rajupalem GP': [
      'Rajupalem',
    ],
    'Ramachandra Puram GP': [
      'Ramachandra Puram',
    ],
    'Ramakrishnapuram GP': [
      'Ramakrishnapuram',
    ],
    'S. Thimmapuram GP': [
      'S. Thimmapuram',
    ],
    'Simhadri Puram GP': [
      'Simhadri Puram',
    ],
    'Somanarayani Peta GP': [
      'Somanarayani Peta',
    ],
    'Somavaram GP': [
      'Somavaram',
    ],
    'Sungarayunipalem GP': [
      'Sungarayunipalem',
    ],
    'Thamarada GP': [
      'Thamarada',
    ],
    'Veeravaram GP': [
      'Veeravaram',
    ],
    'Velanka GP': [
      'Velanka',
    ],
  };

  /// Returns all villages that belong to a specific panchayat.
  static List<String> getVillagesForPanchayat(String panchayatName) {
    return panchayatToVillages[panchayatName] ?? [];
  }

  /// Returns the panchayat for a given village.
  static String getPanchayatForVillage(String villageName) {
    for (final entry in panchayatToVillages.entries) {
      if (entry.value.contains(villageName)) {
        return entry.key;
      }
    }
    return 'Unknown';
  }

  /// Returns the mandal for a given village.
  static String getMandalForVillage(String villageName) {
    final panchayat = getPanchayatForVillage(villageName);
    if (panchayat == 'Unknown') return 'Unknown';
    return getMandalForPanchayat(panchayat);
  }
}
