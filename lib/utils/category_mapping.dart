import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CategoryMapping {
  static const Map<String, List<String>> officerCategories = {
    'Water Functionary': [
      'Water leakage',
      'No water supply',
      'Borewell issues',
      'Pipeline damage',
    ],
    'Line Man': [
      'Power issues',
      'Streetlights',
      'Electrical hazards',
    ],
    'Panchayat Secretary / Ward Member': [
      'Potholes',
      'Road damage',
      'Culverts',
      'Footpaths',
    ],
    'Vetti': [
      'Garbage collection',
      'Waste dumping',
      'Public cleanliness',
    ],
    'ANM / MPHAA': [
      'Health issues',
      'Medical emergencies',
    ],
    'VAA': [
      'Agriculture',
      'Crop issues',
    ],
    'VRO / VRA': [
      'Land records',
      'Certificates',
    ],
    'Anganwadi Worker': [
      'Child welfare',
      'Nutrition',
    ],
    'School HM / Ward Member': [
      'Education',
      'School infrastructure',
    ],
  };

  static const Map<String, List<String>> mandalOfficerCategories = {
    'MPDO': ['Roads', 'Drainage', 'Water', 'Sanitation', 'Panchayat works'],
    'MRO': ['Revenue', 'Land certificates', 'Encroachment'],
    'MAO': ['Agriculture', 'Horticulture', 'Farmer schemes'],
    'MEO': ['Education', 'Scholarships', 'Mid-day meals'],
    'CDPO': ['Women & child welfare', 'Anganwadi mgmt'],
  };

  static String getOfficerRoleForCategory(String specificCategory) {
    switch (specificCategory) {
      case 'Water Supply':
        return 'Water Functionary';
      case 'Electricity':
        return 'Line Man';
      case 'Roads & Infrastructure':
        return 'Panchayat Secretary / Ward Member';
      case 'Sanitation':
        return 'Vetti';
      case 'Health':
        return 'ANM / MPHAA';
      case 'Agriculture':
        return 'VAA';
      case 'Revenue & Certificates':
        return 'VRO / VRA';
      case 'Women & Child Welfare':
        return 'Anganwadi Worker';
      case 'Education':
        return 'School HM / Ward Member';
      default:
        return 'Panchayat Secretary / Ward Member';
    }
  }

  static String getMandalRoleForCategory(String specificCategory) {
    switch (specificCategory) {
      case 'Water Supply':
      case 'Electricity':
      case 'Roads & Infrastructure':
      case 'Sanitation':
        return 'MPDO';
      case 'Revenue & Certificates':
        return 'MRO';
      case 'Agriculture':
        return 'MAO';
      case 'Education':
        return 'MEO';
      case 'Women & Child Welfare':
      case 'Health':
        return 'CDPO';
      default:
        return 'MPDO';
    }
  }

  static List<String> getAllCategories() {
    return [
      'Water Supply',
      'Electricity',
      'Roads & Infrastructure',
      'Agriculture',
      'Health',
      'Sanitation',
      'Revenue & Certificates',
      'Women & Child Welfare',
      'Education',
      'Other Issues',
    ];
  }

  static String getLocalizedCategory(BuildContext context, String category) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return category;
    
    switch (category) {
      case 'Water Supply': return loc.catWaterSupply;
      case 'Electricity': return loc.catElectricity;
      case 'Roads & Infrastructure': return loc.catRoads;
      case 'Agriculture': return loc.catAgriculture;
      case 'Health': return loc.catHealth;
      case 'Sanitation': return loc.catSanitation;
      case 'Revenue & Certificates': return loc.catRevenue;
      case 'Women & Child Welfare': return loc.catWomenChild;
      case 'Education': return loc.catEducation;
      case 'Other Issues': return loc.catOther;
      default: return category;
    }
  }

  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'Water Supply': return Icons.water_drop;
      case 'Electricity': return Icons.bolt;
      case 'Roads & Infrastructure': return Icons.edit_road;
      case 'Agriculture': return Icons.eco;
      case 'Health': return Icons.local_hospital;
      case 'Sanitation': return Icons.delete_outline;
      case 'Revenue & Certificates': return Icons.description;
      case 'Women & Child Welfare': return Icons.groups;
      case 'Education': return Icons.school;
      case 'Other Issues': return Icons.more_horiz;
      default: return Icons.more_horiz;
    }
  }

  static Color getColorForCategory(String category) {
    switch (category) {
      case 'Water Supply': return const Color(0xFF2196F3);
      case 'Electricity': return const Color(0xFFFFC107);
      case 'Roads & Infrastructure': return const Color(0xFF616161);
      case 'Agriculture': return const Color(0xFF4CAF50);
      case 'Health': return const Color(0xFFF44336);
      case 'Sanitation': return const Color(0xFF2E7D32);
      case 'Revenue & Certificates': return const Color(0xFFE91E63);
      case 'Women & Child Welfare': return const Color(0xFFEC407A);
      case 'Education': return const Color(0xFF1565C0);
      case 'Other Issues': return const Color(0xFF757575);
      default: return const Color(0xFF757575);
    }
  }

  // Simulated AI logic to categorize the complaint based on description
  static String determineOfficerRoleWithAI(String selectedCategory, String description) {
    final descLower = description.toLowerCase();
    
    if (descLower.contains('water') || descLower.contains('leak') || descLower.contains('pipeline') || descLower.contains('borewell')) {
      return 'Water Functionary';
    } else if (descLower.contains('power') || descLower.contains('electricity') || descLower.contains('light') || descLower.contains('wire')) {
      return 'Line Man';
    } else if (descLower.contains('road') || descLower.contains('pothole') || descLower.contains('footpath')) {
      return 'Panchayat Secretary / Ward Member';
    } else if (descLower.contains('garbage') || descLower.contains('waste') || descLower.contains('trash') || descLower.contains('clean') || descLower.contains('sanitation')) {
      return 'Vetti';
    } else if (descLower.contains('health') || descLower.contains('hospital') || descLower.contains('medical') || descLower.contains('disease')) {
      return 'ANM / MPHAA';
    } else if (descLower.contains('agriculture') || descLower.contains('crop') || descLower.contains('farm') || descLower.contains('seed')) {
      return 'VAA';
    } else if (descLower.contains('revenue') || descLower.contains('certificate') || descLower.contains('land') || descLower.contains('survey')) {
      return 'VRO / VRA';
    } else if (descLower.contains('women') || descLower.contains('child') || descLower.contains('anganwadi') || descLower.contains('nutrition')) {
      return 'Anganwadi Worker';
    } else if (descLower.contains('education') || descLower.contains('school') || descLower.contains('teacher') || descLower.contains('student')) {
      return 'School HM / Ward Member';
    }
    
    if (officerCategories.containsKey(selectedCategory)) {
      return selectedCategory;
    }
    
    return 'Panchayat Secretary / Ward Member';
  }
}
