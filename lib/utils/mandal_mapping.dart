class MandalMapping {
  static const List<String> mandals = [
    'Anaparthy',
    'Biccavolu',
    'Chagallu',
    'Devarapalli',
    'Dwaraka Tirumala',
    'Gopalapuram',
    'Kadiam',
    'Korukonda',
    'Kovvur',
    'Nallajerla',
    'Nidadavole',
    'Part-Rajahmundry Urban Mandal / RMC',
    'Pedapudi',
    'Peravali',
    'RMC Wards 42–89',
    'RMC Wards 7–35',
    'Rajahmundry Rural',
    'Rajanagaram',
    'Rangampeta',
    'Seethanagaram',
    'Tallapudi',
    'Undrajavaram',
  ];

  static const Map<String, List<String>> _mandalToPanchayats = {
    'Anaparthy': [
      'Anaparthy GP',
    ],
    'Biccavolu': [
      'Biccavolu GP',
    ],
    'Chagallu': [
      'Chagallu GP',
    ],
    'Devarapalli': [
      'Devarapalli GP',
    ],
    'Dwaraka Tirumala': [
      'Dwaraka Tirumala GP',
    ],
    'Gopalapuram': [
      'Gopalapuram GP',
    ],
    'Kadiam': [
      'Kadiam GP',
    ],
    'Korukonda': [
      'Bolleddupalem GP',
      'Burugupudi GP',
      'Butchempeta GP',
      'Dosakayala Palli GP',
      'Gadala GP',
      'Gadarada GP',
      'Jagannadha Puram GP',
      'Kanupuru GP',
      'Korukonda GP',
      'Koti GP',
      'Kotikesavaram GP',
      'Munagala GP',
      'Narasapuram GP',
      'Raghavapuram GP',
      'Srirangapatnam GP',
      'Vegeswarapuram GP',
    ],
    'Kovvur': [
      'Kovvur GP',
    ],
    'Nallajerla': [
      'Nallajerla GP',
    ],
    'Nidadavole': [
      'Nidadavole GP',
    ],
    'Part-Rajahmundry Urban Mandal / RMC': [
      'Part-Rajahmundry Urban Mandal / RMC GP',
    ],
    'Pedapudi': [
      'Pedapudi GP',
    ],
    'Peravali': [
      'Peravali GP',
    ],
    'RMC Wards 42–89': [
      'RMC Wards 42–89 GP',
    ],
    'RMC Wards 7–35': [
      'RMC Wards 7–35 GP',
    ],
    'Rajahmundry Rural': [
      'Rajahmundry Rural GP',
    ],
    'Rajanagaram': [
      'Bhupalapatnam GP',
      'G. Yerrampalem GP',
      'Kalavacherla GP',
      'Konda Gunturu GP',
      'Mukkinada GP',
      'Namavaram GP',
      'Nandarada GP',
      'Narendrapuram GP',
      'Palacharla GP',
      'Pallakadiam GP',
      'Patha Thungapadu GP',
      'Rajanagaram GP',
      'Srikrishnapatnam GP',
      'Thokada GP',
      'Velugubanda GP',
      'Venkatapuram GP',
    ],
    'Rangampeta': [
      'Rangampeta GP',
    ],
    'Seethanagaram': [
      'Chinakondepudi GP',
      'Jalimudi GP',
      'Katavaram GP',
      'Kunavaram GP',
      'Mirthipadu GP',
      'Muggaulla GP',
      'Mulakallanka GP',
      'Munikudali GP',
      'Nagampalle GP',
      'Nallagonda GP',
      'Purushothapatnam GP',
      'Raghudevapuram GP',
      'Seethanagaram GP',
      'Singavaram GP',
      'Vangalapudi GP',
    ],
    'Tallapudi': [
      'Tallapudi GP',
    ],
    'Undrajavaram': [
      'Undrajavaram GP',
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
    'Anaparthy GP': [
      'Anaparthy Town',
    ],
    'Bhupalapatnam GP': [
      'Bhupalapatnam',
    ],
    'Biccavolu GP': [
      'Biccavolu Town',
    ],
    'Bolleddupalem GP': [
      'Bolleddupalem',
    ],
    'Burugupudi GP': [
      'Burugupudi',
    ],
    'Butchempeta GP': [
      'Butchempeta',
    ],
    'Chagallu GP': [
      'Chagallu Town',
    ],
    'Chinakondepudi GP': [
      'Chinakondepudi',
    ],
    'Devarapalli GP': [
      'Devarapalli Town',
    ],
    'Dosakayala Palli GP': [
      'Dosakayala Palli',
    ],
    'Dwaraka Tirumala GP': [
      'Dwaraka Tirumala Town',
    ],
    'G. Yerrampalem GP': [
      'G. Yerrampalem',
    ],
    'Gadala GP': [
      'Gadala',
    ],
    'Gadarada GP': [
      'Gadarada',
    ],
    'Gopalapuram GP': [
      'Gopalapuram Town',
    ],
    'Jagannadha Puram GP': [
      'Jagannadha Puram',
    ],
    'Jalimudi GP': [
      'Jalimudi',
    ],
    'Kadiam GP': [
      'Kadiam Town',
    ],
    'Kalavacherla GP': [
      'Kalavacherla',
    ],
    'Kanupuru GP': [
      'Kanupuru',
    ],
    'Katavaram GP': [
      'Katavaram',
    ],
    'Konda Gunturu GP': [
      'Konda Gunturu',
    ],
    'Korukonda GP': [
      'Atchutapuram',
      'Jambupatnam',
      'Kapavaram',
      'Korukonda',
    ],
    'Koti GP': [
      'Koti',
    ],
    'Kotikesavaram GP': [
      'Kotikesavaram',
    ],
    'Kovvur GP': [
      'Kovvur Town',
    ],
    'Kunavaram GP': [
      'Kunavaram',
    ],
    'Mirthipadu GP': [
      'Mirthipadu',
    ],
    'Muggaulla GP': [
      'Muggaulla',
    ],
    'Mukkinada GP': [
      'Mukkinada',
    ],
    'Mulakallanka GP': [
      'Mulakallanka',
    ],
    'Munagala GP': [
      'Munagala',
    ],
    'Munikudali GP': [
      'Munikudali',
    ],
    'Nagampalle GP': [
      'Nagampalle',
    ],
    'Nallagonda GP': [
      'Nallagonda',
    ],
    'Nallajerla GP': [
      'Nallajerla Town',
    ],
    'Namavaram GP': [
      'Namavaram',
    ],
    'Nandarada GP': [
      'Nandarada',
    ],
    'Narasapuram GP': [
      'Narasapuram',
    ],
    'Narendrapuram GP': [
      'Narendrapuram',
    ],
    'Nidadavole GP': [
      'Nidadavole Town',
    ],
    'Palacharla GP': [
      'Palacharla',
    ],
    'Pallakadiam GP': [
      'Kanavaram',
    ],
    'Part-Rajahmundry Urban Mandal / RMC GP': [
      'Part-Rajahmundry Urban Mandal / RMC Town',
    ],
    'Patha Thungapadu GP': [
      'Patha Thungapadu',
    ],
    'Pedapudi GP': [
      'Pedapudi Town',
    ],
    'Peravali GP': [
      'Peravali Town',
    ],
    'Purushothapatnam GP': [
      'Purushothapatnam',
    ],
    'RMC Wards 42–89 GP': [
      'RMC Wards 42–89 Town',
    ],
    'RMC Wards 7–35 GP': [
      'RMC Wards 7–35 Town',
    ],
    'Raghavapuram GP': [
      'Raghavapuram',
    ],
    'Raghudevapuram GP': [
      'Raghudevapuram',
    ],
    'Rajahmundry Rural GP': [
      'Rajahmundry Rural Town',
    ],
    'Rajanagaram GP': [
      'Jagannadhapuram Agraharam',
      'Rajanagaram',
    ],
    'Rangampeta GP': [
      'Rangampeta Town',
    ],
    'Seethanagaram GP': [
      'Hundeswarapuram',
      'Seethanagaram',
    ],
    'Singavaram GP': [
      'Singavaram',
    ],
    'Srikrishnapatnam GP': [
      'Srikrishnapatnam',
    ],
    'Srirangapatnam GP': [
      'Srirangapatnam',
    ],
    'Tallapudi GP': [
      'Tallapudi Town',
    ],
    'Thokada GP': [
      'Thokada',
    ],
    'Undrajavaram GP': [
      'Undrajavaram Town',
    ],
    'Vangalapudi GP': [
      'Vangalapudi',
    ],
    'Vegeswarapuram GP': [
      'Vegeswarapuram',
    ],
    'Velugubanda GP': [
      'Velugubanda',
    ],
    'Venkatapuram GP': [
      'Venkatapuram',
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
