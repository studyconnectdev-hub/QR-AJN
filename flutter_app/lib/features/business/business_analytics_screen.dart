import 'package:flutter/material.dart';

import '../../core/services/business_analytics_service.dart';
import '../../core/services/firebase_bootstrap.dart';

class BusinessAnalyticsScreen extends StatefulWidget {
  const BusinessAnalyticsScreen({super.key});

  @override
  State<BusinessAnalyticsScreen> createState() =>
      _BusinessAnalyticsScreenState();
}

class _BusinessAnalyticsScreenState extends State<BusinessAnalyticsScreen> {
  late Future<BusinessAnalyticsSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = BusinessAnalyticsService.loadSummary();
  }

  void _reload() {
    setState(() => _future = BusinessAnalyticsService.loadSummary());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Business Analytics'),
          actions: <Widget>[
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: FutureBuilder<BusinessAnalyticsSummary>(
          future: _future,
          builder: (context, snapshot) {
            if (!FirebaseBootstrap.available) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Connect Firebase to use business analytics.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            final data = snapshot.data ?? const BusinessAnalyticsSummary();
            final metrics = <(IconData, String, int)>[
              (Icons.visibility_outlined, 'Profile views', data.profileViews),
              (Icons.person_search_outlined, 'Unique visitors', data.uniqueVisitors),
              (Icons.contact_page_outlined, 'Contact saves', data.contactSaves),
              (Icons.phone_outlined, 'Phone clicks', data.phoneClicks),
              (Icons.chat_outlined, 'WhatsApp clicks', data.whatsappClicks),
              (Icons.email_outlined, 'Email clicks', data.emailClicks),
              (Icons.map_outlined, 'Map clicks', data.mapClicks),
              (Icons.inventory_2_outlined, 'Product views', data.productViews),
              (Icons.download_outlined, 'Brochure downloads', data.brochureDownloads),
              (Icons.currency_rupee_rounded, 'UPI clicks', data.upiClicks),
              (Icons.assignment_ind_outlined, 'Lead submissions', data.leads),
              (Icons.qr_code_scanner_rounded, 'Dynamic QR scans', data.dynamicScans),
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        Color(0xFF2563EB),
                        Color(0xFF7C3AED),
                        Color(0xFFEC4899),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.analytics_rounded, color: Colors.white, size: 42),
                      SizedBox(height: 10),
                      Text(
                        'Privacy-safe engagement summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Counts are aggregated by the optional production backend. Raw QR payloads are never shown here.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metrics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final metric = metrics[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(metric.$1, color: Theme.of(context).colorScheme.primary),
                            const Spacer(),
                            Text(
                              '${metric.$3}',
                              style: const TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(metric.$2),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.cloud_queue_rounded),
                    title: Text('Advanced analytics backend'),
                    subtitle: Text(
                      'The included Blaze backend adds redirect routing, daily aggregation, expiry, scan limits and billing verification. Deploy it only after upgrading Firebase billing.',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}
