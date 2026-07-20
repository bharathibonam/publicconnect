import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('te'),
  ];

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get adminManagement;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Smart Gov'**
  String get appName;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @avgResolutionTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Resolution Time'**
  String get avgResolutionTime;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @broadcastSection.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Alert'**
  String get broadcastSection;

  /// No description provided for @callCitizen.
  ///
  /// In en, this message translates to:
  /// **'Call Citizen'**
  String get callCitizen;

  /// No description provided for @callTollFree.
  ///
  /// In en, this message translates to:
  /// **'Call Toll-Free'**
  String get callTollFree;

  /// No description provided for @categoryOfficerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Category Officer Dashboard'**
  String get categoryOfficerDashboard;

  /// No description provided for @chatOfficer.
  ///
  /// In en, this message translates to:
  /// **'Chat with Officer'**
  String get chatOfficer;

  /// No description provided for @chatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Chat with Us'**
  String get chatWithUs;

  /// No description provided for @citizenSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Citizen Satisfaction'**
  String get citizenSatisfaction;

  /// No description provided for @citizensServed.
  ///
  /// In en, this message translates to:
  /// **'Citizens Served'**
  String get citizensServed;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// No description provided for @complaintAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Complaint Analytics'**
  String get complaintAnalytics;

  /// No description provided for @complaintDashboard.
  ///
  /// In en, this message translates to:
  /// **'Complaint Dashboard'**
  String get complaintDashboard;

  /// No description provided for @completionPercent.
  ///
  /// In en, this message translates to:
  /// **'Completion Percentage'**
  String get completionPercent;

  /// No description provided for @constituency.
  ///
  /// In en, this message translates to:
  /// **'Constituency'**
  String get constituency;

  /// No description provided for @constituencyNameJsp.
  ///
  /// In en, this message translates to:
  /// **'Pithapuram'**
  String get constituencyNameJsp;

  /// No description provided for @constituencyNameTdp.
  ///
  /// In en, this message translates to:
  /// **'Rajahmundry'**
  String get constituencyNameTdp;

  /// No description provided for @constituencyOffice.
  ///
  /// In en, this message translates to:
  /// **'Constituency Office'**
  String get constituencyOffice;

  /// No description provided for @constituencySummary.
  ///
  /// In en, this message translates to:
  /// **'Constituency Summary'**
  String get constituencySummary;

  /// No description provided for @departmentAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Department Announcement'**
  String get departmentAnnouncement;

  /// No description provided for @departmentPerformance.
  ///
  /// In en, this message translates to:
  /// **'Department Performance'**
  String get departmentPerformance;

  /// No description provided for @emergencyNotification.
  ///
  /// In en, this message translates to:
  /// **'Emergency Notification'**
  String get emergencyNotification;

  /// No description provided for @escalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get escalate;

  /// No description provided for @escalated.
  ///
  /// In en, this message translates to:
  /// **'Escalated'**
  String get escalated;

  /// No description provided for @fileComplaint.
  ///
  /// In en, this message translates to:
  /// **'File Complaint'**
  String get fileComplaint;

  /// No description provided for @findLocation.
  ///
  /// In en, this message translates to:
  /// **'Find Location'**
  String get findLocation;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @govSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get govSchemes;

  /// No description provided for @helpDesk.
  ///
  /// In en, this message translates to:
  /// **'Help Desk'**
  String get helpDesk;

  /// No description provided for @helpline.
  ///
  /// In en, this message translates to:
  /// **'Helpline'**
  String get helpline;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @mandalOfficerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Mandal Officer Dashboard'**
  String get mandalOfficerDashboard;

  /// No description provided for @mandalSummary.
  ///
  /// In en, this message translates to:
  /// **'Mandal Summary'**
  String get mandalSummary;

  /// No description provided for @mlaAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'MLA Announcements'**
  String get mlaAnnouncements;

  /// No description provided for @mlaDashboard.
  ///
  /// In en, this message translates to:
  /// **'MLA Dashboard'**
  String get mlaDashboard;

  /// No description provided for @mlaNameJsp.
  ///
  /// In en, this message translates to:
  /// **'Pawan Kalyan'**
  String get mlaNameJsp;

  /// No description provided for @mlaNameTdp.
  ///
  /// In en, this message translates to:
  /// **'G M Harish Balayogi'**
  String get mlaNameTdp;

  /// No description provided for @myDepartmentSummary.
  ///
  /// In en, this message translates to:
  /// **'My Department Summary'**
  String get myDepartmentSummary;

  /// No description provided for @myWard.
  ///
  /// In en, this message translates to:
  /// **'My Ward'**
  String get myWard;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @newComplaints.
  ///
  /// In en, this message translates to:
  /// **'New Complaints'**
  String get newComplaints;

  /// No description provided for @noComplaints.
  ///
  /// In en, this message translates to:
  /// **'No complaints submitted yet.'**
  String get noComplaints;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @partyNameJsp.
  ///
  /// In en, this message translates to:
  /// **'JSP'**
  String get partyNameJsp;

  /// No description provided for @partyNameTdp.
  ///
  /// In en, this message translates to:
  /// **'TDP'**
  String get partyNameTdp;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @primaryServicesStatus.
  ///
  /// In en, this message translates to:
  /// **'Primary Services Status'**
  String get primaryServicesStatus;

  /// No description provided for @priorityQueue.
  ///
  /// In en, this message translates to:
  /// **'Priority Queue'**
  String get priorityQueue;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @publicNotify.
  ///
  /// In en, this message translates to:
  /// **'Public Notification'**
  String get publicNotify;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickFile.
  ///
  /// In en, this message translates to:
  /// **'Quick File'**
  String get quickFile;

  /// No description provided for @quickServices.
  ///
  /// In en, this message translates to:
  /// **'Quick Services'**
  String get quickServices;

  /// No description provided for @recentActivityTimeline.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity Timeline'**
  String get recentActivityTimeline;

  /// No description provided for @recentComplaints.
  ///
  /// In en, this message translates to:
  /// **'Recent Complaints'**
  String get recentComplaints;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @resolutionProgress.
  ///
  /// In en, this message translates to:
  /// **'Resolution Progress'**
  String get resolutionProgress;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @slaBreached.
  ///
  /// In en, this message translates to:
  /// **'SLA Breached'**
  String get slaBreached;

  /// No description provided for @slaTracker.
  ///
  /// In en, this message translates to:
  /// **'SLA Tracker'**
  String get slaTracker;

  /// No description provided for @subCategoryDetails.
  ///
  /// In en, this message translates to:
  /// **'Sub-Category Details'**
  String get subCategoryDetails;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @supportSection.
  ///
  /// In en, this message translates to:
  /// **'Support & Helpline'**
  String get supportSection;

  /// No description provided for @systemConfig.
  ///
  /// In en, this message translates to:
  /// **'System Configuration'**
  String get systemConfig;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Connect. Resolve. Empower.'**
  String get tagline;

  /// No description provided for @thisMonthTrend.
  ///
  /// In en, this message translates to:
  /// **'This Month\'s Trend'**
  String get thisMonthTrend;

  /// No description provided for @todayServiceRequests.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Service Requests'**
  String get todayServiceRequests;

  /// No description provided for @topMandals.
  ///
  /// In en, this message translates to:
  /// **'Top Mandals'**
  String get topMandals;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalComplaints.
  ///
  /// In en, this message translates to:
  /// **'Total Complaints'**
  String get totalComplaints;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @trackStatus.
  ///
  /// In en, this message translates to:
  /// **'Track Status'**
  String get trackStatus;

  /// No description provided for @uploadWorkCompletion.
  ///
  /// In en, this message translates to:
  /// **'Upload Work Completion'**
  String get uploadWorkCompletion;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewMoreServices.
  ///
  /// In en, this message translates to:
  /// **'View More Services'**
  String get viewMoreServices;

  /// No description provided for @villageWiseComplaints.
  ///
  /// In en, this message translates to:
  /// **'Village Wise Complaints'**
  String get villageWiseComplaints;

  /// No description provided for @voiceBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Voice Broadcast'**
  String get voiceBroadcast;

  /// No description provided for @wardMemberDashboard.
  ///
  /// In en, this message translates to:
  /// **'Ward Member Dashboard'**
  String get wardMemberDashboard;

  /// No description provided for @wardOfficer.
  ///
  /// In en, this message translates to:
  /// **'Ward Officer'**
  String get wardOfficer;

  /// No description provided for @wardMembers.
  ///
  /// In en, this message translates to:
  /// **'Ward Members'**
  String get wardMembers;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeGaru.
  ///
  /// In en, this message translates to:
  /// **'{name} Garu'**
  String welcomeGaru(Object name);

  /// No description provided for @constituencySuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} Constituency'**
  String constituencySuffix(Object name);

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get newAnnouncement;

  /// No description provided for @broadcastHistory.
  ///
  /// In en, this message translates to:
  /// **'Broadcast History'**
  String get broadcastHistory;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated successfully'**
  String get profileUpdated;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload photo'**
  String get photoUploadFailed;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @generateExcel.
  ///
  /// In en, this message translates to:
  /// **'Generate Excel Sheet'**
  String get generateExcel;

  /// No description provided for @generatingExcel.
  ///
  /// In en, this message translates to:
  /// **'Generating Excel Sheet...'**
  String get generatingExcel;

  /// No description provided for @wardSummary.
  ///
  /// In en, this message translates to:
  /// **'Ward Summary'**
  String get wardSummary;

  /// No description provided for @whatsappSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support'**
  String get whatsappSupport;

  /// No description provided for @catWaterSupply.
  ///
  /// In en, this message translates to:
  /// **'Water Supply'**
  String get catWaterSupply;

  /// No description provided for @catElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get catElectricity;

  /// No description provided for @catRoads.
  ///
  /// In en, this message translates to:
  /// **'Roads & Infrastructure'**
  String get catRoads;

  /// No description provided for @catAgriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get catAgriculture;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catSanitation.
  ///
  /// In en, this message translates to:
  /// **'Sanitation'**
  String get catSanitation;

  /// No description provided for @catRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue & Certificates'**
  String get catRevenue;

  /// No description provided for @catWomenChild.
  ///
  /// In en, this message translates to:
  /// **'Women & Child Welfare'**
  String get catWomenChild;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other Issues'**
  String get catOther;

  /// No description provided for @mlaNameBjp.
  ///
  /// In en, this message translates to:
  /// **'Daggubati Purandeswari'**
  String get mlaNameBjp;

  /// No description provided for @constituencyNameBjp.
  ///
  /// In en, this message translates to:
  /// **'Rajahmundry'**
  String get constituencyNameBjp;

  /// No description provided for @partyNameBjp.
  ///
  /// In en, this message translates to:
  /// **'BJP'**
  String get partyNameBjp;

  /// No description provided for @voiceComplaint.
  ///
  /// In en, this message translates to:
  /// **'Voice Complaint'**
  String get voiceComplaint;

  /// No description provided for @trackComplaint.
  ///
  /// In en, this message translates to:
  /// **'Track Complaint'**
  String get trackComplaint;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @welfareSchemes.
  ///
  /// In en, this message translates to:
  /// **'Welfare Schemes'**
  String get welfareSchemes;

  /// No description provided for @emergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencyServices;

  /// No description provided for @developmentWorks.
  ///
  /// In en, this message translates to:
  /// **'Development Works'**
  String get developmentWorks;

  /// No description provided for @schools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get schools;

  /// No description provided for @juniorColleges.
  ///
  /// In en, this message translates to:
  /// **'Junior Colleges'**
  String get juniorColleges;

  /// No description provided for @degreeColleges.
  ///
  /// In en, this message translates to:
  /// **'Degree Colleges'**
  String get degreeColleges;

  /// No description provided for @polytechnicColleges.
  ///
  /// In en, this message translates to:
  /// **'Polytechnic Colleges'**
  String get polytechnicColleges;

  /// No description provided for @itiColleges.
  ///
  /// In en, this message translates to:
  /// **'ITI Colleges'**
  String get itiColleges;

  /// No description provided for @govHospitals.
  ///
  /// In en, this message translates to:
  /// **'Government Hospitals'**
  String get govHospitals;

  /// No description provided for @pvtHospitals.
  ///
  /// In en, this message translates to:
  /// **'Private Hospitals'**
  String get pvtHospitals;

  /// No description provided for @policeStations.
  ///
  /// In en, this message translates to:
  /// **'Police Stations'**
  String get policeStations;

  /// No description provided for @fireStations.
  ///
  /// In en, this message translates to:
  /// **'Fire Stations'**
  String get fireStations;

  /// No description provided for @municipalOffice.
  ///
  /// In en, this message translates to:
  /// **'Municipal Office'**
  String get municipalOffice;

  /// No description provided for @meesevaCentres.
  ///
  /// In en, this message translates to:
  /// **'MeeSeva Centres'**
  String get meesevaCentres;

  /// No description provided for @libraries.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// No description provided for @publicParks.
  ///
  /// In en, this message translates to:
  /// **'Public Parks'**
  String get publicParks;

  /// No description provided for @busStations.
  ///
  /// In en, this message translates to:
  /// **'Bus Stations'**
  String get busStations;

  /// No description provided for @railwayInfo.
  ///
  /// In en, this message translates to:
  /// **'Railway Information'**
  String get railwayInfo;

  /// No description provided for @otherPublicServices.
  ///
  /// In en, this message translates to:
  /// **'Other Public Services'**
  String get otherPublicServices;

  /// No description provided for @phc.
  ///
  /// In en, this message translates to:
  /// **'Primary Health Centres (PHCs)'**
  String get phc;

  /// No description provided for @chc.
  ///
  /// In en, this message translates to:
  /// **'Community Health Centres'**
  String get chc;

  /// No description provided for @vetHospitals.
  ///
  /// In en, this message translates to:
  /// **'Veterinary Hospitals'**
  String get vetHospitals;

  /// No description provided for @anganwadi.
  ///
  /// In en, this message translates to:
  /// **'Anganwadi Centres'**
  String get anganwadi;

  /// No description provided for @banks.
  ///
  /// In en, this message translates to:
  /// **'Banks & Financial Hubs'**
  String get banks;

  /// No description provided for @postOffices.
  ///
  /// In en, this message translates to:
  /// **'Post Offices'**
  String get postOffices;

  /// No description provided for @govOffices.
  ///
  /// In en, this message translates to:
  /// **'Government Offices'**
  String get govOffices;

  /// No description provided for @rationShops.
  ///
  /// In en, this message translates to:
  /// **'Ration Shops (PDS)'**
  String get rationShops;

  /// No description provided for @catSocialWelfare.
  ///
  /// In en, this message translates to:
  /// **'Social Welfare'**
  String get catSocialWelfare;

  /// No description provided for @catEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get catEconomy;

  /// No description provided for @catGovernment.
  ///
  /// In en, this message translates to:
  /// **'Government'**
  String get catGovernment;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catPublicSafety.
  ///
  /// In en, this message translates to:
  /// **'Public Safety'**
  String get catPublicSafety;

  /// No description provided for @catFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get catFinancial;

  /// No description provided for @catUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get catUtilities;

  /// No description provided for @farmersWelfare.
  ///
  /// In en, this message translates to:
  /// **'Farmers Welfare'**
  String get farmersWelfare;

  /// No description provided for @studentsEducation.
  ///
  /// In en, this message translates to:
  /// **'Students & Education'**
  String get studentsEducation;

  /// No description provided for @womenEmpowerment.
  ///
  /// In en, this message translates to:
  /// **'Women Empowerment'**
  String get womenEmpowerment;

  /// No description provided for @seniorCitizens.
  ///
  /// In en, this message translates to:
  /// **'Senior Citizens'**
  String get seniorCitizens;

  /// No description provided for @youthEmployment.
  ///
  /// In en, this message translates to:
  /// **'Youth & Employment'**
  String get youthEmployment;

  /// No description provided for @housingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Housing Schemes'**
  String get housingSchemes;

  /// No description provided for @healthcareCashless.
  ///
  /// In en, this message translates to:
  /// **'Healthcare & Cashless'**
  String get healthcareCashless;

  /// No description provided for @businessMsme.
  ///
  /// In en, this message translates to:
  /// **'Business & MSME'**
  String get businessMsme;

  /// No description provided for @workersLabour.
  ///
  /// In en, this message translates to:
  /// **'Workers & Labour'**
  String get workersLabour;

  /// No description provided for @subsidiesEnergy.
  ///
  /// In en, this message translates to:
  /// **'Subsidies & Energy'**
  String get subsidiesEnergy;

  /// No description provided for @fishermenWelfare.
  ///
  /// In en, this message translates to:
  /// **'Fishermen Welfare'**
  String get fishermenWelfare;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
