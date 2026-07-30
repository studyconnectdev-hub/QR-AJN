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
    this.coverUrl = '',
    this.photoUrl = '',
    this.logoUrl = '',
    this.phone = '',
    this.whatsapp = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.mapUrl = '',
    this.services = const <String>[],
    this.products = const <String>[],
    this.priceList = const <String>[],
    this.galleryUrls = const <String>[],
    this.videoUrls = const <String>[],
    this.brochureUrl = '',
    this.upiId = '',
    this.reviewUrl = '',
    this.leadFormUrl = '',
    this.appointmentUrl = '',
    this.openingHours = '',
    this.branchLocations = const <String>[],
    this.languages = const <String>[],
    this.testimonials = const <String>[],
    this.certifications = const <String>[],
    this.offers = const <String>[],
    this.socialLinks = const <String, String>{},
    this.template = 'professional',
    this.primaryColor = '#2563EB',
    this.published = true,
  });

  final String slug;
  final String name;
  final String title;
  final String company;
  final String coverUrl;
  final String photoUrl;
  final String logoUrl;
  final String phone;
  final String whatsapp;
  final String email;
  final String website;
  final String address;
  final String mapUrl;
  final List<String> services;
  final List<String> products;
  final List<String> priceList;
  final List<String> galleryUrls;
  final List<String> videoUrls;
  final String brochureUrl;
  final String upiId;
  final String reviewUrl;
  final String leadFormUrl;
  final String appointmentUrl;
  final String openingHours;
  final List<String> branchLocations;
  final List<String> languages;
  final List<String> testimonials;
  final List<String> certifications;
  final List<String> offers;
  final Map<String, String> socialLinks;
  final String template;
  final String primaryColor;
  final bool published;

  String get publicUrl => '${AppConfig.publicDomain}/@$slug';

  Map<String, dynamic> toFirestore(String ownerUid) => <String, dynamic>{
        'slug': slug,
        'ownerUid': ownerUid,
        'name': name,
        'title': title,
        'company': company,
        'coverUrl': coverUrl,
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
        'priceList': priceList,
        'galleryUrls': galleryUrls,
        'videoUrls': videoUrls,
        'brochureUrl': brochureUrl,
        'upiId': upiId,
        'reviewUrl': reviewUrl,
        'leadFormUrl': leadFormUrl,
        'appointmentUrl': appointmentUrl,
        'openingHours': openingHours,
        'branchLocations': branchLocations,
        'languages': languages,
        'testimonials': testimonials,
        'certifications': certifications,
        'offers': offers,
        'socialLinks': socialLinks,
        'template': template,
        'primaryColor': primaryColor,
        'published': published,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory BusinessProfile.fromFirestore(Map<String, dynamic> data) =>
      BusinessProfile(
        slug: '${data['slug'] ?? ''}',
        name: '${data['name'] ?? ''}',
        title: '${data['title'] ?? ''}',
        company: '${data['company'] ?? ''}',
        coverUrl: '${data['coverUrl'] ?? ''}',
        photoUrl: '${data['photoUrl'] ?? ''}',
        logoUrl: '${data['logoUrl'] ?? ''}',
        phone: '${data['phone'] ?? ''}',
        whatsapp: '${data['whatsapp'] ?? ''}',
        email: '${data['email'] ?? ''}',
        website: '${data['website'] ?? ''}',
        address: '${data['address'] ?? ''}',
        mapUrl: '${data['mapUrl'] ?? ''}',
        services: _stringList(data['services']),
        products: _stringList(data['products']),
        priceList: _stringList(data['priceList']),
        galleryUrls: _stringList(data['galleryUrls']),
        videoUrls: _stringList(data['videoUrls']),
        brochureUrl: '${data['brochureUrl'] ?? ''}',
        upiId: '${data['upiId'] ?? ''}',
        reviewUrl: '${data['reviewUrl'] ?? ''}',
        leadFormUrl: '${data['leadFormUrl'] ?? ''}',
        appointmentUrl: '${data['appointmentUrl'] ?? ''}',
        openingHours: '${data['openingHours'] ?? ''}',
        branchLocations: _stringList(data['branchLocations']),
        languages: _stringList(data['languages']),
        testimonials: _stringList(data['testimonials']),
        certifications: _stringList(data['certifications']),
        offers: _stringList(data['offers']),
        socialLinks: Map<String, String>.from(
          data['socialLinks'] is Map
              ? data['socialLinks'] as Map
              : const <String, String>{},
        ),
        template: '${data['template'] ?? 'professional'}',
        primaryColor: '${data['primaryColor'] ?? '#2563EB'}',
        published: data['published'] != false,
      );

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'[\r\n]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }
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

    final profileQuery = await FirebaseFirestore.instance
        .collection('business_profiles')
        .where('ownerUid', isEqualTo: user.uid)
        .get();
    final linkQuery = await FirebaseFirestore.instance
        .collection('dynamic_links')
        .where('ownerUid', isEqualTo: user.uid)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final document in profileQuery.docs) {
      batch.delete(document.reference);
    }
    for (final document in linkQuery.docs) {
      batch.delete(document.reference);
    }
    batch.delete(
      FirebaseFirestore.instance.collection('users').doc(user.uid),
    );
    await batch.commit();
  }

  static Future<void> save(BusinessProfile profile) async {
    if (!FirebaseBootstrap.available) {
      throw StateError('Firebase is not configured.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Sign in to publish a business profile.');
    }

    final slug = normalizeSlug(profile.slug);
    if (slug.length < 3 || slug.length > 48) {
      throw StateError('Choose a profile URL between 3 and 48 characters.');
    }
    if (profile.name.trim().isEmpty) {
      throw StateError('Enter a profile or business name.');
    }

    final reference =
        FirebaseFirestore.instance.collection('business_profiles').doc(slug);
    final existing = await reference.get();
    if (existing.exists && existing.data()?['ownerUid'] != user.uid) {
      throw StateError('That profile URL is already taken.');
    }

    final normalizedProfile = BusinessProfile(
      slug: slug,
      name: profile.name.trim(),
      title: profile.title.trim(),
      company: profile.company.trim(),
      coverUrl: profile.coverUrl.trim(),
      photoUrl: profile.photoUrl.trim(),
      logoUrl: profile.logoUrl.trim(),
      phone: profile.phone.trim(),
      whatsapp: profile.whatsapp.trim(),
      email: profile.email.trim(),
      website: profile.website.trim(),
      address: profile.address.trim(),
      mapUrl: profile.mapUrl.trim(),
      services: profile.services,
      products: profile.products,
      priceList: profile.priceList,
      galleryUrls: profile.galleryUrls,
      videoUrls: profile.videoUrls,
      brochureUrl: profile.brochureUrl.trim(),
      upiId: profile.upiId.trim(),
      reviewUrl: profile.reviewUrl.trim(),
      leadFormUrl: profile.leadFormUrl.trim(),
      appointmentUrl: profile.appointmentUrl.trim(),
      openingHours: profile.openingHours.trim(),
      branchLocations: profile.branchLocations,
      languages: profile.languages,
      testimonials: profile.testimonials,
      certifications: profile.certifications,
      offers: profile.offers,
      socialLinks: profile.socialLinks,
      template: profile.template,
      primaryColor: profile.primaryColor,
      published: profile.published,
    );

    await reference.set(
      normalizedProfile.toFirestore(user.uid),
      SetOptions(merge: true),
    );
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      <String, dynamic>{
        'businessProfileSlug': slug,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
