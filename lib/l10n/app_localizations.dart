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
  /// **'Jaggampeta'**
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
  /// **'Jyothula Nehru'**
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
