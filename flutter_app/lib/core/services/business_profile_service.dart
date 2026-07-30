import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import 'firebase_bootstrap.dart';

class BusinessProfile {
  const BusinessProfile({
    required this.slug,
    required this.name,
    this.title = '',
    this.company = '',
    this.photoUrl = '',
    this.logoUrl = '',
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.mapUrl = '',
    this.services = '',
    this.products = '',
    this.brochureUrl = '',
    this.upiId = '',
    this.appointmentUrl = '',
    this.socialLinks = const {},
    this.template = 'aurora',
    this.primaryColor = '#2563EB',
    this.published = true,
  });

  final String slug;
  final String name;
  final String title;
  final String company;
  final String photoUrl;
  final String logoUrl;
  final String phone;
  final String whatsapp;
  final String email;
  final String website;
  final String address;
  final String mapUrl;
  final String services;
  final String products;
  final String brochureUrl;
  final String upiId;
  final String appointmentUrl;
  final Map<String, String> socialLinks;
  final String template;
  final String primaryColor;
  final bool published;

  String get publicUrl => '${AppConfig.publicDomain}/@$slug';

  Map<String, dynamic> toFirestore(String ownerUid) => {
        'slug': slug,
        'ownerUid': ownerUid,
        'name': name,
        'title': title,
        'company': company,
        'photoUrl': photoUrl,
        'logoUrl': logoUrl,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'website': website,
        'address': address,
        'mapUrl': mapUrl,
        'services': services,
        'products': products,
        'brochureUrl': brochureUrl,
        'upiId': upiId,
        'appointmentUrl': appointmentUrl,
        'socialLinks': socialLinks,
        'template': template,
        'primaryColor': primaryColor,
        'published': published,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory BusinessProfile.fromFirestore(Map<String, dynamic> data) => BusinessProfile(
        slug: '${data['slug'] ?? ''}',
        name: '${data['name'] ?? ''}',
        title: '${data['title'] ?? ''}',
        company: '${data['company'] ?? ''}',
        photoUrl: '${data['photoUrl'] ?? ''}',
        logoUrl: '${data['logoUrl'] ?? ''}',
        phone: '${data['phone'] ?? ''}',
        whatsapp: '${data['whatsapp'] ?? ''}',
        email: '${data['email'] ?? ''}',
        website: '${data['website'] ?? ''}',
        address: '${data['address'] ?? ''}',
        mapUrl: '${data['mapUrl'] ?? ''}',
        services: '${data['services'] ?? ''}',
        products: '${data['products'] ?? ''}',
        brochureUrl: '${data['brochureUrl'] ?? ''}',
        upiId: '${data['upiId'] ?? ''}',
        appointmentUrl: '${data['appointmentUrl'] ?? ''}',
        socialLinks: Map<String, String>.from(data['socialLinks'] is Map ? data['socialLinks'] as Map : const {}),
        template: '${data['template'] ?? 'aurora'}',
        primaryColor: '${data['primaryColor'] ?? '#2563EB'}',
        published: data['published'] != false,
      );
}

class BusinessProfileService {
  const BusinessProfileService._();

  static String normalizeSlug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  static Future<BusinessProfile?> loadMine() async {
    if (!FirebaseBootstrap.available) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final query = await FirebaseFirestore.instance
        .collection('business_profiles')
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return BusinessProfile.fromFirestore(query.docs.first.data());
  }


  static Future<void> deleteMine() async {
    if (!FirebaseBootstrap.available) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('business_profiles')
        .where('ownerUid', isEqualTo: user.uid)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final document in query.docs) {
      batch.delete(document.reference);
    }
    batch.delete(FirebaseFirestore.instance.collection('users').doc(user.uid));
    await batch.commit();
  }

  static Future<void> save(BusinessProfile profile) async {
    if (!FirebaseBootstrap.available) throw StateError('Firebase is not configured.');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to publish a business profile.');
    final slug = normalizeSlug(profile.slug);
    if (slug.length < 3) throw StateError('Choose a profile URL with at least 3 characters.');
    final reference = FirebaseFirestore.instance.collection('business_profiles').doc(slug);
    final existing = await reference.get();
    if (existing.exists && existing.data()?['ownerUid'] != user.uid) {
      throw StateError('That profile URL is already taken.');
    }
    await reference.set(profile.toFirestore(user.uid), SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'businessProfileSlug': slug,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
