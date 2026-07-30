import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_bootstrap.dart';

class BusinessAnalyticsSummary {
  const BusinessAnalyticsSummary({
    this.profileViews = 0,
    this.uniqueVisitors = 0,
    this.contactSaves = 0,
    this.phoneClicks = 0,
    this.whatsappClicks = 0,
    this.emailClicks = 0,
    this.mapClicks = 0,
    this.productViews = 0,
    this.brochureDownloads = 0,
    this.upiClicks = 0,
    this.leads = 0,
    this.dynamicScans = 0,
  });

  final int profileViews;
  final int uniqueVisitors;
  final int contactSaves;
  final int phoneClicks;
  final int whatsappClicks;
  final int emailClicks;
  final int mapClicks;
  final int productViews;
  final int brochureDownloads;
  final int upiClicks;
  final int leads;
  final int dynamicScans;

  factory BusinessAnalyticsSummary.fromMap(Map<String, dynamic> data) {
    int count(String key) =>
        data[key] is num ? (data[key] as num).toInt() : 0;
    return BusinessAnalyticsSummary(
      profileViews: count('profileViews'),
      uniqueVisitors: count('uniqueVisitors'),
      contactSaves: count('contactSaves'),
      phoneClicks: count('phoneClicks'),
      whatsappClicks: count('whatsappClicks'),
      emailClicks: count('emailClicks'),
      mapClicks: count('mapClicks'),
      productViews: count('productViews'),
      brochureDownloads: count('brochureDownloads'),
      upiClicks: count('upiClicks'),
      leads: count('leads'),
      dynamicScans: count('dynamicScans'),
    );
  }
}

class BusinessAnalyticsService {
  const BusinessAnalyticsService._();

  static Future<BusinessAnalyticsSummary> loadSummary() async {
    if (!FirebaseBootstrap.available) {
      return const BusinessAnalyticsSummary();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const BusinessAnalyticsSummary();

    final snapshot = await FirebaseFirestore.instance
        .collection('business_analytics')
        .doc(user.uid)
        .get();
    return BusinessAnalyticsSummary.fromMap(
      snapshot.data() ?? const <String, dynamic>{},
    );
  }
}
