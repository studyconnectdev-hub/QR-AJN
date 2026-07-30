import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy by design')),
      body: ListView(children: const [
        Card(child: ListTile(leading: Icon(Icons.history_toggle_off), title: Text('No scan history'), subtitle: Text('The application does not create a permanent list of scanned or generated QR values.'))),
        Card(child: ListTile(leading: Icon(Icons.person_off), title: Text('No compulsory account'), subtitle: Text('The scanner opens directly. There is no email, phone, password or social sign-in screen.'))),
        Card(child: ListTile(leading: Icon(Icons.memory), title: Text('In-memory processing'), subtitle: Text('Scan content exists only while the current result is open and is not added to permanent history.'))),
        Card(child: ListTile(leading: Icon(Icons.analytics_outlined), title: Text('Privacy-conscious telemetry'), subtitle: Text('Analytics can record that a URL or UPI code was scanned, but never the scanned content, UPI ID, domain or message.'))),
        Card(child: ListTile(leading: Icon(Icons.report_outlined), title: Text('Sanitized reports'), subtitle: Text('Community reports send only a one-way SHA-256 hash of the domain, a reason code and timestamp.'))),
        Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Before publishing, replace the contact placeholders in privacy_policy/privacy_policy.html and host it on a public HTTPS webpage. Review the Play Console Data Safety form after every SDK or advertising change.'))),
      ]),
    );
  }
}
