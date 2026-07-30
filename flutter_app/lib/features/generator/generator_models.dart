import 'dart:convert';
import 'package:flutter/material.dart';

enum GeneratorType {
  website,
  text,
  phone,
  sms,
  email,
  contact,
  wifi,
  location,
  calendar,
  emergency,
  upi,
  businessProfile,
  product,
  menu,
  priceList,
  feedback,
  googleReview,
  coupon,
  eventTicket,
  booking,
  whatsapp,
  telegram,
  instagram,
  facebook,
  youtube,
  linkedin,
  appDownload,
  appLink,
  multiLink,
  document,
}

enum QrPalette { ocean, violet, mint, sunset, rose, gold, midnight, mono, aqua, berry, forest, royal }
enum QrModuleShape { square, rounded, dots, diamond }

class GeneratorCategory {
  const GeneratorCategory({
    required this.type,
    required this.title,
    required this.shortLabel,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.fields,
    this.premium = false,
  });

  final GeneratorType type;
  final String title;
  final String shortLabel;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final List<String> fields;
  final bool premium;
}

const generatorCategories = <GeneratorCategory>[
  GeneratorCategory(type: GeneratorType.website, title: 'Website', shortLabel: 'Open a web page', subtitle: 'Create a secure website QR.', icon: Icons.language_rounded, colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)], fields: ['Website URL']),
  GeneratorCategory(type: GeneratorType.text, title: 'Plain Text', shortLabel: 'Notes & messages', subtitle: 'Encode private text or instructions.', icon: Icons.text_fields_rounded, colors: [Color(0xFF64748B), Color(0xFF334155)], fields: ['Text content']),
  GeneratorCategory(type: GeneratorType.phone, title: 'Phone Call', shortLabel: 'Call a number', subtitle: 'Create a tap-to-call action.', icon: Icons.phone_rounded, colors: [Color(0xFF10B981), Color(0xFF059669)], fields: ['Phone number']),
  GeneratorCategory(type: GeneratorType.sms, title: 'SMS', shortLabel: 'Send a message', subtitle: 'Open a prefilled SMS.', icon: Icons.sms_rounded, colors: [Color(0xFF22C55E), Color(0xFF16A34A)], fields: ['Phone number', 'Message']),
  GeneratorCategory(type: GeneratorType.email, title: 'Email', shortLabel: 'Compose email', subtitle: 'Open a prepared email draft.', icon: Icons.email_rounded, colors: [Color(0xFF2563EB), Color(0xFF06B6D4)], fields: ['Recipient email', 'Subject', 'Message']),
  GeneratorCategory(type: GeneratorType.contact, title: 'Contact Card', shortLabel: 'Share a vCard', subtitle: 'Share complete contact details.', icon: Icons.contact_page_rounded, colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)], fields: ['Full name', 'Phone number', 'Email address', 'Company / organization', 'Website']),
  GeneratorCategory(type: GeneratorType.wifi, title: 'Wi-Fi', shortLabel: 'Connect quickly', subtitle: 'Share Wi-Fi credentials safely.', icon: Icons.wifi_rounded, colors: [Color(0xFF06B6D4), Color(0xFF0D9488)], fields: ['Network name (SSID)', 'Password', 'Security: WPA, WEP or nopass', 'Hidden network: yes or no']),
  GeneratorCategory(type: GeneratorType.location, title: 'Location', shortLabel: 'Open in maps', subtitle: 'Share coordinates and a label.', icon: Icons.location_on_rounded, colors: [Color(0xFFF43F5E), Color(0xFFF97316)], fields: ['Latitude', 'Longitude', 'Location label']),
  GeneratorCategory(type: GeneratorType.calendar, title: 'Calendar Event', shortLabel: 'Add an event', subtitle: 'Share an event invitation.', icon: Icons.event_rounded, colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], fields: ['Event title', 'Start: YYYYMMDDTHHMMSS', 'End: YYYYMMDDTHHMMSS', 'Location', 'Description']),
  GeneratorCategory(type: GeneratorType.emergency, title: 'Emergency Card', shortLabel: 'Important details', subtitle: 'Share emergency and medical contact information.', icon: Icons.health_and_safety_rounded, colors: [Color(0xFFEF4444), Color(0xFF7C3AED)], fields: ['Person name', 'Emergency phone', 'Blood group', 'Allergies / note']),
  GeneratorCategory(type: GeneratorType.upi, title: 'UPI Payment', shortLabel: 'Pay safely', subtitle: 'Create a UPI request with visible details.', icon: Icons.currency_rupee_rounded, colors: [Color(0xFF7C3AED), Color(0xFFEC4899)], fields: ['UPI ID', 'Payee name', 'Amount (optional)', 'Payment note', 'Reference']),
  GeneratorCategory(type: GeneratorType.businessProfile, title: 'Business Profile', shortLabel: 'qrajn.online card', subtitle: 'Publish an editable professional business card.', icon: Icons.badge_rounded, colors: [Color(0xFF2563EB), Color(0xFF7C3AED)], fields: [], premium: true),
  GeneratorCategory(type: GeneratorType.product, title: 'Product Info', shortLabel: 'Product identity', subtitle: 'Share product and catalogue information.', icon: Icons.inventory_2_rounded, colors: [Color(0xFF0D9488), Color(0xFF2563EB)], fields: ['Product ID', 'Product name', 'Product URL', 'Price', 'Details']),
  GeneratorCategory(type: GeneratorType.menu, title: 'Restaurant Menu', shortLabel: 'Digital menu', subtitle: 'Share a restaurant or café menu.', icon: Icons.restaurant_menu_rounded, colors: [Color(0xFFF97316), Color(0xFFEF4444)], fields: ['Menu URL']),
  GeneratorCategory(type: GeneratorType.priceList, title: 'Price List', shortLabel: 'Products & rates', subtitle: 'Share a price-list or catalogue link.', icon: Icons.request_quote_rounded, colors: [Color(0xFFF59E0B), Color(0xFFEA580C)], fields: ['Price-list URL']),
  GeneratorCategory(type: GeneratorType.feedback, title: 'Feedback Form', shortLabel: 'Collect responses', subtitle: 'Share a customer feedback form.', icon: Icons.rate_review_rounded, colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)], fields: ['Feedback form URL']),
  GeneratorCategory(type: GeneratorType.googleReview, title: 'Google Review', shortLabel: 'Collect reviews', subtitle: 'Open a Google review page.', icon: Icons.star_rounded, colors: [Color(0xFFFACC15), Color(0xFFF97316)], fields: ['Google review URL']),
  GeneratorCategory(type: GeneratorType.coupon, title: 'Coupon', shortLabel: 'Offer or discount', subtitle: 'Create a customer offer.', icon: Icons.local_offer_rounded, colors: [Color(0xFFF59E0B), Color(0xFFE11D48)], fields: ['Coupon code', 'Offer details', 'Expiry date', 'Terms']),
  GeneratorCategory(type: GeneratorType.eventTicket, title: 'Event Ticket', shortLabel: 'Ticket information', subtitle: 'Create structured event-ticket data.', icon: Icons.confirmation_number_rounded, colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)], fields: ['Ticket ID', 'Event name', 'Ticket holder', 'Event date', 'Venue']),
  GeneratorCategory(type: GeneratorType.booking, title: 'Appointment', shortLabel: 'Booking link', subtitle: 'Share an appointment or reservation page.', icon: Icons.calendar_month_rounded, colors: [Color(0xFF06B6D4), Color(0xFF6366F1)], fields: ['Booking URL']),
  GeneratorCategory(type: GeneratorType.whatsapp, title: 'WhatsApp', shortLabel: 'Open a chat', subtitle: 'Start a WhatsApp chat.', icon: Icons.chat_rounded, colors: [Color(0xFF22C55E), Color(0xFF0D9488)], fields: ['Phone with country code', 'Prefilled message']),
  GeneratorCategory(type: GeneratorType.telegram, title: 'Telegram', shortLabel: 'Open a profile', subtitle: 'Share a Telegram username or link.', icon: Icons.send_rounded, colors: [Color(0xFF38BDF8), Color(0xFF0284C7)], fields: ['Telegram username or URL']),
  GeneratorCategory(type: GeneratorType.instagram, title: 'Instagram', shortLabel: 'Open a profile', subtitle: 'Share an Instagram profile.', icon: Icons.camera_alt_rounded, colors: [Color(0xFFEC4899), Color(0xFF7C3AED)], fields: ['Instagram username or URL']),
  GeneratorCategory(type: GeneratorType.facebook, title: 'Facebook', shortLabel: 'Open a page', subtitle: 'Share a Facebook page or profile.', icon: Icons.facebook_rounded, colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)], fields: ['Facebook page name or URL']),
  GeneratorCategory(type: GeneratorType.youtube, title: 'YouTube', shortLabel: 'Video or channel', subtitle: 'Share a YouTube video or channel.', icon: Icons.play_circle_fill_rounded, colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], fields: ['YouTube URL']),
  GeneratorCategory(type: GeneratorType.linkedin, title: 'LinkedIn', shortLabel: 'Professional profile', subtitle: 'Share a professional profile.', icon: Icons.business_center_rounded, colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)], fields: ['LinkedIn profile or company URL']),
  GeneratorCategory(type: GeneratorType.appDownload, title: 'App Download', shortLabel: 'Store landing page', subtitle: 'Share Play Store or app landing page.', icon: Icons.install_mobile_rounded, colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)], fields: ['App download URL']),
  GeneratorCategory(type: GeneratorType.appLink, title: 'App / Deep Link', shortLabel: 'Open an app action', subtitle: 'Encode an application URI.', icon: Icons.open_in_new_rounded, colors: [Color(0xFF0284C7), Color(0xFF4F46E5)], fields: ['App or deep-link URI']),
  GeneratorCategory(type: GeneratorType.multiLink, title: 'Multi-link Page', shortLabel: 'All links in one page', subtitle: 'Share a qrajn.online link hub.', icon: Icons.hub_rounded, colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)], fields: ['Multi-link page URL'], premium: true),
  GeneratorCategory(type: GeneratorType.document, title: 'Document Link', shortLabel: 'Share a file', subtitle: 'Open a cloud document.', icon: Icons.description_rounded, colors: [Color(0xFF64748B), Color(0xFF2563EB)], fields: ['Document URL']),
];

GeneratorCategory categoryFor(GeneratorType type) => generatorCategories.firstWhere((item) => item.type == type);

String buildGeneratorPayload(GeneratorType type, List<String> values) {
  final v = List<String>.generate(5, (index) => index < values.length ? values[index].trim() : '');
  if (type != GeneratorType.businessProfile && v.first.isEmpty) return '';
  switch (type) {
    case GeneratorType.website:
    case GeneratorType.menu:
    case GeneratorType.priceList:
    case GeneratorType.feedback:
    case GeneratorType.googleReview:
    case GeneratorType.booking:
    case GeneratorType.appDownload:
    case GeneratorType.multiLink:
    case GeneratorType.document:
      return normalizeUrl(v[0]);
    case GeneratorType.text:
      return v[0];
    case GeneratorType.phone:
      return 'tel:${v[0]}';
    case GeneratorType.sms:
      return Uri(scheme: 'sms', path: v[0], queryParameters: {if (v[1].isNotEmpty) 'body': v[1]}).toString();
    case GeneratorType.email:
      return Uri(scheme: 'mailto', path: v[0], queryParameters: {if (v[1].isNotEmpty) 'subject': v[1], if (v[2].isNotEmpty) 'body': v[2]}).toString();
    case GeneratorType.contact:
      return 'BEGIN:VCARD\nVERSION:3.0\nFN:${escapeVCard(v[0])}\nTEL:${escapeVCard(v[1])}\nEMAIL:${escapeVCard(v[2])}\nORG:${escapeVCard(v[3])}\nURL:${escapeVCard(v[4])}\nEND:VCARD';
    case GeneratorType.wifi:
      final hidden = ['yes', 'true', '1'].contains(v[3].toLowerCase());
      return 'WIFI:T:${escapeWifi(v[2].isEmpty ? 'WPA' : v[2])};S:${escapeWifi(v[0])};P:${escapeWifi(v[1])};H:${hidden ? 'true' : 'false'};;';
    case GeneratorType.location:
      return v[1].isEmpty ? '' : 'geo:${v[0]},${v[1]}?q=${Uri.encodeQueryComponent('${v[0]},${v[1]}(${v[2].isEmpty ? '${v[0]},${v[1]}' : v[2]})')}';
    case GeneratorType.calendar:
      return 'BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:${escapeVCard(v[0])}\nDTSTART:${calendarValue(v[1])}\nDTEND:${calendarValue(v[2])}\nLOCATION:${escapeVCard(v[3])}\nDESCRIPTION:${escapeVCard(v[4])}\nEND:VEVENT\nEND:VCALENDAR';
    case GeneratorType.emergency:
      return jsonEncode({'type': 'qrajn_emergency', 'name': v[0], 'phone': v[1], 'bloodGroup': v[2], 'note': v[3]});
    case GeneratorType.upi:
      return Uri(scheme: 'upi', host: 'pay', queryParameters: {'pa': v[0], if (v[1].isNotEmpty) 'pn': v[1], if (v[2].isNotEmpty) 'am': v[2], if (v[3].isNotEmpty) 'tn': v[3], if (v[4].isNotEmpty) 'tr': v[4], 'cu': 'INR'}).toString();
    case GeneratorType.businessProfile:
      return '';
    case GeneratorType.product:
      return jsonEncode({'type': 'qrajn_product', 'id': v[0], 'name': v[1], 'url': normalizeUrl(v[2]), 'price': v[3], 'details': v[4]});
    case GeneratorType.coupon:
      return jsonEncode({'type': 'qrajn_coupon', 'code': v[0], 'offer': v[1], 'expiry': v[2], 'terms': v[3]});
    case GeneratorType.eventTicket:
      return jsonEncode({'type': 'qrajn_event_ticket', 'ticket': v[0], 'event': v[1], 'holder': v[2], 'date': v[3], 'venue': v[4]});
    case GeneratorType.whatsapp:
      final number = v[0].replaceAll(RegExp(r'[^0-9]'), '');
      return number.isEmpty ? '' : Uri.https('wa.me', '/$number', {if (v[1].isNotEmpty) 'text': v[1]}).toString();
    case GeneratorType.telegram:
      return v[0].contains('://') ? v[0] : 'https://t.me/${v[0].replaceFirst('@', '')}';
    case GeneratorType.instagram:
      return v[0].contains('://') ? v[0] : 'https://www.instagram.com/${v[0].replaceFirst('@', '')}/';
    case GeneratorType.facebook:
      return v[0].contains('://') ? v[0] : 'https://www.facebook.com/${v[0].replaceFirst('@', '')}';
    case GeneratorType.youtube:
      return normalizeUrl(v[0]);
    case GeneratorType.linkedin:
      return v[0].contains('://') ? v[0] : 'https://www.linkedin.com/in/${v[0].replaceFirst('@', '')}';
    case GeneratorType.appLink:
      return v[0];
  }
}

String normalizeUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  if (RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(trimmed)) return trimmed;
  return 'https://$trimmed';
}

String escapeWifi(String value) => value.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(':', r'\:');
String escapeVCard(String value) => value.replaceAll(r'\', r'\\').replaceAll('\n', r'\n').replaceAll(';', r'\;').replaceAll(',', r'\,');
String calendarValue(String value) => value.replaceAll(RegExp(r'[^0-9TZ]'), '');
