import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'firebase_bootstrap.dart';

class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = const [];
  bool storeAvailable = false;
  bool loading = false;
  bool isPremium = false;
  bool isBusiness = false;
  bool serverVerified = false;
  String plan = 'free';
  String? message;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    isPremium = preferences.getBool('premium_provisional') ?? false;
    isBusiness = preferences.getBool('business_provisional') ?? false;
    plan = preferences.getString('premium_plan') ?? (isPremium ? 'pro' : 'free');
    final provisionalUntil = preferences.getInt('premium_provisional_until') ?? 0;
    if (!serverVerified &&
        isPremium &&
        provisionalUntil > 0 &&
        DateTime.now().millisecondsSinceEpoch > provisionalUntil) {
      isPremium = false;
      isBusiness = false;
      plan = 'free';
      message = 'Premium verification expired. Restore the purchase or reconnect to verify it.';
      await _persist(clearProvisionalExpiry: true);
    }
    notifyListeners();

    _subscription ??= _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        message = 'Purchase update failed: $error';
        notifyListeners();
      },
    );

    try {
      storeAvailable = await _store.isAvailable();
      if (storeAvailable) {
        final response = await _store.queryProductDetails(AppConfig.premiumProductIds);
        products = response.productDetails;
        if (response.error != null) message = response.error!.message;
      }
    } catch (error) {
      message = 'Play Billing is unavailable: $error';
    }
    await refreshServerEntitlement();
    notifyListeners();
  }

  Future<void> refreshServerEntitlement() async {
    if (!FirebaseBootstrap.available) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('entitlements').doc(user.uid).get();
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final active = data['active'] == true;
      plan = active ? '${data['plan'] ?? 'pro'}' : 'free';
      isBusiness = active && plan == 'business';
      isPremium = active;
      serverVerified = true;
      message = active ? 'Premium entitlement verified.' : 'No active premium entitlement was found.';
      await _persist(clearProvisionalExpiry: true);
    } catch (error) {
      debugPrint('Entitlement refresh skipped: $error');
    }
  }

  ProductDetails? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> buy(ProductDetails product) async {
    loading = true;
    message = null;
    notifyListeners();
    try {
      await _store.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (error) {
      message = 'Purchase could not start: $error';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> restore() async {
    loading = true;
    message = 'Restoring purchases…';
    notifyListeners();
    try {
      await _store.restorePurchases();
    } catch (error) {
      message = 'Restore failed: $error';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        loading = true;
        message = 'Purchase is pending.';
      } else if (purchase.status == PurchaseStatus.error) {
        loading = false;
        message = purchase.error?.message ?? 'Purchase failed.';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _activateProvisional(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        loading = false;
        message = 'Purchase cancelled.';
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  Future<void> _activateProvisional(PurchaseDetails purchase) async {
    plan = AppConfig.isBusinessProduct(purchase.productID) ? 'business' : 'pro';
    isBusiness = plan == 'business';
    isPremium = true;
    serverVerified = false;
    loading = false;
    message = 'Purchase received. Premium is available temporarily while secure verification completes.';
    await _persist(
      provisionalUntil: DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch,
    );
    await _queueReceipt(purchase);
    await _verifyWithBackend(purchase);
  }


  Future<void> _verifyWithBackend(PurchaseDetails purchase) async {
    if (!FirebaseBootstrap.available) return;
    final baseUrl = FirebaseBootstrap.text('blaze_api_base_url');
    final user = FirebaseAuth.instance.currentUser;
    if (baseUrl.isEmpty || user == null) return;
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/v1/billing/google-play/verify'));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.write(jsonEncode({
        'productId': purchase.productID,
        'purchaseToken': purchase.verificationData.serverVerificationData,
      }));
      final response = await request.close();
      final raw = await utf8.decodeStream(response);
      client.close(force: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final active = data['active'] == true;
        plan = active ? '${data['plan'] ?? plan}' : 'free';
        isBusiness = active && plan == 'business';
        isPremium = active;
        serverVerified = true;
        message = active ? 'Premium verified securely.' : 'The purchase is not currently active.';
        await _persist(clearProvisionalExpiry: true);
      } else {
        debugPrint('Purchase verification deferred: ${response.statusCode} $raw');
      }
    } catch (error) {
      debugPrint('Purchase verification deferred: $error');
    }
  }

  Future<void> _queueReceipt(PurchaseDetails purchase) async {
    if (!FirebaseBootstrap.available) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final id = purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate ?? DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance
          .collection('pending_purchase_receipts')
          .doc(user.uid)
          .collection('items')
          .doc(id.replaceAll('/', '_'))
          .set({
        'productId': purchase.productID,
        'purchaseId': purchase.purchaseID,
        'transactionDate': purchase.transactionDate,
        'source': purchase.verificationData.source,
        'serverVerificationData': purchase.verificationData.serverVerificationData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Receipt queue skipped: $error');
    }
  }

  Future<void> _persist({
    int? provisionalUntil,
    bool clearProvisionalExpiry = false,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('premium_provisional', isPremium);
    await preferences.setBool('business_provisional', isBusiness);
    await preferences.setString('premium_plan', plan);
    if (clearProvisionalExpiry) {
      await preferences.remove('premium_provisional_until');
    } else if (provisionalUntil != null) {
      await preferences.setInt('premium_provisional_until', provisionalUntil);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
