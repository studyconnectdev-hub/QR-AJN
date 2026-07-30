import 'package:flutter/material.dart';
import '../../core/models/scan_models.dart';
import '../../core/services/action_service.dart';
import '../../core/services/community_report_service.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/settings/app_settings.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.payload,
    required this.assessment,
  });

  final ScanPayload payload;
  final SafetyAssessment assessment;

  Color riskColor() => switch (assessment.level) {
        RiskLevel.trusted || RiskLevel.safe => Colors.green,
        RiskLevel.caution => Colors.orange,
        RiskLevel.suspicious => Colors.deepOrange,
        RiskLevel.dangerous => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final color = riskColor();
    return Scaffold(
      appBar: AppBar(title: Text(payload.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: color),
                      const SizedBox(width: 10),
                      Text(
                        '${assessment.label} • ${assessment.score}/100',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(payload.summary),
                  if (AppSettings.instance.showFullDestination && payload.actionUri != null) ...[
                    const SizedBox(height: 10),
                    SelectableText(payload.actionUri!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (payload.details.isNotEmpty)
            Card(
              child: Column(
                children: payload.details.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .map(
                      (entry) => ListTile(
                        dense: true,
                        title: Text(entry.key),
                        subtitle: SelectableText(entry.value),
                      ),
                    )
                    .toList(),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Safety explanation', style: TextStyle(fontWeight: FontWeight.w900)),
                  ...assessment.reasons.map(
                    (reason) => ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(reason),
                    ),
                  ),
                  ...assessment.warnings.map(
                    (warning) => ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: color),
                      title: Text(warning),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => ActionService.copy(payload.raw),
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => ActionService.share(payload.raw),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              if (payload.actionUri != null)
                FilledButton.icon(
                  onPressed: assessment.level == RiskLevel.dangerous && AppSettings.instance.blockDangerous
                      ? null
                      : () => confirmOpen(context),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(payload.type == ScanContentType.upi ? 'Choose payment app' : 'Open safely'),
                ),
              if (payload.type == ScanContentType.url &&
                  FirebaseBootstrap.flag('community_reporting_enabled', fallback: true))
                OutlinedButton.icon(
                  onPressed: () => report(context),
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Report'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> confirmOpen(BuildContext context) async {
    if (payload.type == ScanContentType.upi) {
      if (AppSettings.instance.confirmPayments) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Verify payment details'),
            content: Text(
              'Payee: ${payload.details['Payee name']?.isNotEmpty == true ? payload.details['Payee name'] : payload.details['UPI ID']}\n'
              'UPI ID: ${payload.details['UPI ID'] ?? ''}\n'
              'Amount: ${payload.details['Amount'] ?? 'Not fixed'} ${payload.details['Currency'] ?? 'INR'}\n\n'
              'Confirm the recipient and amount again inside the payment app.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Continue')),
            ],
          ),
        );
        if (confirmed != true) return;
      }

      final apps = await ActionService.availablePaymentApps();
      if (!context.mounted) return;
      final preferred = AppSettings.instance.preferredPaymentApp;
      final ordered = [...apps]
        ..sort((a, b) {
          if (a.id == preferred || a.packageName == preferred) return -1;
          if (b.id == preferred || b.packageName == preferred) return 1;
          return 0;
        });
      final app = await showModalBottomSheet<PaymentApp>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Choose installed payment app', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('QR AJN only forwards the verified UPI request. Payment is completed inside your selected app.'),
              ),
              ...ordered.map(
                (item) => ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(item.label),
                  trailing: item.id == preferred || item.packageName == preferred
                      ? const Icon(Icons.star_rounded)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
              ),
            ],
          ),
        ),
      );
      if (app != null) {
        final opened = await ActionService.open(
          payload,
          paymentPackage: app.packageName.isEmpty ? null : app.packageName,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No compatible payment app could open this request.')),
          );
        }
      }
      return;
    }

    if (!AppSettings.instance.confirmExternalLinks) {
      await ActionService.open(payload);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Open external destination?'),
        content: SelectableText(payload.actionUri!),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Open')),
        ],
      ),
    );
    if (ok == true) await ActionService.open(payload);
  }

  Future<void> report(BuildContext context) async {
    final sent = await CommunityReportService.report(payload.raw, 'user_suspicious');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sent ? 'Sanitized report submitted.' : 'Report not sent.')),
      );
    }
  }
}
