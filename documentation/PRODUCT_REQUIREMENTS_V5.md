# QR AJN V5 Product Requirements

What I understand for QR AJN

QR AJN should become two connected products, not only a basic scanner:

QR AJN mobile app — fast private scanning and advanced QR creation.

qrajn.online business platform — professional digital profiles, business cards, templates, dynamic QR links and business tools.

The scanner must remain usable without login. Login should appear only when someone wants to create or manage a cloud business profile.

1. Final mobile app structure

Bottom navigation

Only:

Home
Scanner
Generator

Home screen

Remove these cards completely:

UPI Safety
Smart Redirects
QR Studio
SafeScan
Business QR
Connect & Share

Home should contain only two large professional cards:

Scan QR

Opens Scanner immediately.

Camera animation.

“Fast, secure QR and barcode scanning.”

Blue–cyan gradient.

Create QR

Opens Generator categories.

Animated QR preview.

“Create professional QR codes for personal and business use.”

Purple–pink gradient.

Top-right:

Settings icon

No history, saved scans or unnecessary dashboard cards.

2. Advanced Scanner requirements

The scanner should work more like Telegram’s QR scanner: fast, focused and automatic.

Camera intelligence

Automatic QR detection.

Automatic zoom when the QR is far away.

QR position tracking.

Tap-to-focus.

Pinch-to-zoom.

Manual zoom slider.

Low-light detection.

Flash recommendation.

Camera switching.

Gallery-image scanning.

Rotated and partially damaged QR detection.

Small QR detection.

Fast duplicate-frame suppression.

Animated target lock.

Vibration after successful detection.

Pause scanner while showing a result.

QR target selection

When several QR codes appear in the camera:

Draw a border around each detected QR.

Let the user tap the required QR.

Process only the selected QR.

Do not create a batch list or permanent history.

Result handling

The app should identify and safely open:

Website URLs.

App deep links.

Android intent links.

UPI payment QR codes.

PhonePe-compatible UPI links.

Google Pay-compatible UPI links.

Paytm and BHIM.

Wi-Fi.

Contacts.

Phone calls.

SMS.

Email.

WhatsApp.

Telegram.

Maps and locations.

Calendar events.

App Store and Play Store links.

Social profiles.

Product barcodes.

ISBN.

Plain text.

Custom JSON.

Event tickets.

Business profiles hosted on qrajn.online.

For payment codes, first show:

Payee name
UPI ID
Amount
Currency
Payment note
Selected payment application

Then ask for confirmation before redirecting.

3. Generator redesign

When the user opens Generator, show only a colorful two-column category grid.

No large form should appear until a category is selected.

Category flow

Choose category
→ Enter information
→ Customize design
→ Preview
→ Validate scannability
→ Create QR
→ Download / Share / Copy

Recommended categories

Personal and communication

Website

Plain text

Phone call

SMS

Email

Contact card

Wi-Fi

Location

Calendar event

Emergency contact

Payments and business

UPI payment

Business profile

Product information

Restaurant menu

Price list

Feedback form

Google Review

Coupon

Event ticket

Appointment or booking

Social and apps

WhatsApp

Telegram

Instagram

Facebook

YouTube

LinkedIn

App download

App deep link

Multi-link page

Document link

Each card needs its own icon, gradient, short description and opening animation.

4. Generator subpages

Every QR category should have a dedicated subpage instead of reusing one confusing form.

Example: UPI QR

Fields:

UPI ID
Payee name
Amount
Currency
Transaction note
Reference
Fixed or editable amount

Actions:

Preview payment details
Generate QR
Test scan
Download
Share
Copy UPI link

Example: Wi-Fi QR

Fields:

Network name
Password
Security type
Hidden network

The password should have show/hide controls.

Example: Business profile QR

Fields:

Profile name
Professional title
Company
Profile photo
Logo
Phone
WhatsApp
Email
Website
Address
Map location
Social links
Products
Services
Brochure
UPI payment link
Appointment link

Example: Social profile

Platform selection.

Username or full link.

Link validation.

Profile preview.

Open-test button.

QR generation.

5. QR customization studio

QR AJN must provide more customization than the current implementation.

Design controls

Solid colours.

Two-colour gradients.

Three-colour gradients.

Background colour.

Transparent background.

Pattern shapes.

Dot, square, rounded and diamond modules.

Multiple eye shapes.

Different eye colours.

Logo upload.

Logo background plate.

Logo size adjustment.

Frame styles.

“Scan Me” captions.

Custom caption.

Margin control.

Error-correction level.

Print-size selector.

PNG export.

SVG export.

PDF print export.

High-resolution export.

Quality protection

Customization must never destroy scannability. The app should calculate:

Contrast
Quiet-zone validity
Logo obstruction
Payload length
Error-correction strength
Estimated print size
Scan quality score

Professional QR platforms already provide logo, colour, frame, high-quality export and editable or trackable QR options; QR AJN should combine these with its own scan-quality validation. ()

6. qrajn.online business platform

This is the most important future direction.

Public profile links

Examples:

qrajn.online/@anjan
qrajn.online/business/study-connect
qrajn.online/card/vignesh
qrajn.online/q/AB12CD

A recipient should not need to install QR AJN or create an account to view a public business card.

Competitors already support cards shared through QR, links, NFC, email signatures, wallet passes and virtual-meeting backgrounds. Uniqode also supports custom URLs, two-way contact sharing and lead-generation settings. ()

Business profile page

Each profile should support:

Cover image.

Profile photo.

Business logo.

Name and designation.

Company details.

Save contact button.

Call button.

WhatsApp button.

Email button.

Directions button.

Website.

Social links.

Products.

Services.

Price list.

Gallery.

Videos.

Brochure download.

UPI payment.

Google Review.

Lead form.

Appointment booking.

Opening hours.

Branch locations.

Languages.

Testimonials.

Certifications.

Offers.

Custom theme.

Profile templates

Create templates for:

Individual professional.

Company employee.

Freelancer.

Shop.

Restaurant.

Doctor.

Lawyer.

Real-estate agent.

Teacher.

Student portfolio.

Event organizer.

Photographer.

Influencer.

Hotel.

School.

Product catalogue.

Emergency profile.

7. QR AJN profile builder

The website should have a step-by-step builder:

1. Select template
2. Enter profile details
3. Add buttons and links
4. Add products or services
5. Choose colours and fonts
6. Preview mobile page
7. Select QR design
8. Publish profile
9. Share profile and QR

Users should be able to update their profile later without printing a new QR. This is the central advantage of dynamic QR links; QR TIGER and other platforms use landing-page-backed vCard QR codes and editable dynamic destinations. ()

8. Accounts and privacy

There should be no compulsory login for scanning or ordinary static QR creation.

Login is needed only for:

Creating a qrajn.online profile
Editing a published profile
Dynamic QR management
Business templates
Lead collection
Analytics
Team management

Recommended login methods:

Google.

Email magic link.

Email and password.

Phone login later because phone verification can have additional costs.

9. Backend architecture

Firebase Spark launch

Use Spark initially for:

Firebase Authentication.

Firestore profiles.

Firebase Hosting.

Remote Config.

App Check.

Crashlytics.

Performance Monitoring.

FCM.

Basic profile templates.

Trusted-domain and safety-rule updates.

Firebase currently provides Spark access to no-cost Firebase products and free quotas for Firestore and Hosting. Firestore’s free allowance includes 50,000 reads, 20,000 writes and 20,000 deletes per day, plus 1 GiB storage. ()

App Check with Play Integrity should protect the Android app’s Firebase requests. ()

Blaze upgrade later

Required for:

Fast dynamic redirects.

Secure server-side link changes.

Advanced analytics.

Custom-domain routing.

Scheduled QR expiry.

Webhooks.

Automated reports.

Team billing.

Large-scale lead processing.

Cloud Run.

Pub/Sub.

BigQuery.

Cloud Run, Pub/Sub and similar paid Google Cloud services are not available on Spark, so these must be enabled only after upgrading to Blaze. ()

10. Dynamic QR backend logic

A dynamic QR should contain:

https://qrajn.online/q/AB12CD

Backend flow:

Scan QR
→ Validate QR status
→ Check expiry
→ Check scan limits
→ Check device and country rules
→ Record privacy-safe analytics
→ Select destination
→ Redirect

Routing options:

Android → Play Store.

iPhone → App Store.

Desktop → Website.

India → Indian campaign.

Different languages → localized page.

Business open → current offer.

Business closed → contact page.

Expired event → expired page.

Broken destination → backup page.

11. Business analytics

Business users should see:

Total profile views.

Unique visitors.

Contact saves.

Phone-button clicks.

WhatsApp clicks.

Email clicks.

Map clicks.

Product views.

Brochure downloads.

UPI-button clicks.

Lead submissions.

Best-performing QR.

City and device summaries.

Date-range comparison.

Flowcode emphasizes measurable QR interactions and first-party conversion data, while HiHello includes engagement and lead analytics. ()

12. Main pending work

Priority

Pending

Critical

Remove all six advanced-action cards from Home

Critical

Keep only Scan QR and Create QR cards

Critical

Implement Scanner auto-zoom and QR target tracking

Critical

Add tap-to-select when multiple QR codes are visible

Critical

Complete all redirect types and payment-app routing

Critical

Rebuild Generator as category-only grid

Critical

Build separate form subpage for every generator category

Critical

Add preview, validation, download, share and copy workflow

Critical

Confirm package name com.qr.ajn throughout Android and Firebase

Critical

Build and verify the correctly signed Play Store AAB

High

Build QR customization studio

High

Add SVG/PDF/high-resolution export

High

Add QR scan-quality validator

High

Build qrajn.online website

High

Configure DNS, SSL and Firebase Hosting

High

Create optional business-profile authentication

High

Build business-profile editor and public profile pages

High

Add professional profile templates

High

Add save-contact/vCard download

High

Add WhatsApp, call, email, maps and social actions

High

Add product, service, gallery and brochure sections

High

Build dynamic QR database model

Medium

Lead-capture forms

Medium

Profile analytics

Medium

Team and employee business cards

Medium

Custom branded profile URLs

Medium

Google Wallet and Apple Wallet passes

Medium

NFC sharing

Medium

Email-signature QR generator

Medium

Business template marketplace

Future

Custom domains for customers

Future

Advanced routing rules

Future

Anti-counterfeit product QR

Future

Event tickets and redemption

Future

Inventory and attendance

Future

Premium subscriptions

Final product direction

QR AJN should become:

A private QR scanner, professional QR creator and digital business identity platform.

Its main advantages should be:

Fast scanner with intelligent auto-zoom
Safe UPI and redirect handling
30+ professional QR categories
Advanced QR customization
qrajn.online business profiles
Editable dynamic QR destinations
Beautiful templates
No compulsory login for scanning
Professional business tools when users choose to sign in

The first development priority is now Scanner intelligence + clean Generator category flow. After that, qrajn.online should become the central business-profile and dynami