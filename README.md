# Becky's Kitchen

<div align="center">

**Fresh food, simple ordering, and kitchen-made happiness - all in one app.**

A mobile storefront and order management app built for Becky's Kitchen with Flutter, Firebase, Supabase, and Xendit.

</div>

---

## About the App

Becky's Kitchen lets customers browse the menu, build a cart, select exactly what they want to checkout, choose a payment method, and track their orders. Administrators can manage the menu and update order and payment statuses from the app.

## Features

- Email and Google authentication
- Customer profiles
- Product categories and menu browsing
- Selectable cart items with live totals
- Checkout for selected items only
- Xendit online payment
- Pay-at-store payment option
- Order and payment status tracking
- Firebase-backed products and orders
- Supabase Edge Functions for secure Xendit invoice processing
- Admin product and order management

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter |
| Authentication | Firebase Authentication |
| Database and app data | Cloud Firestore |
| Online payments | Xendit |
| Payment backend | Supabase Edge Functions |
| Payment records | Supabase PostgreSQL |
| State management | Provider |

## Project Structure

```text
lib/
  models/                 App data models
  screens/                Customer and admin screens
  services/               Firebase and Xendit services
  widgets/                Reusable UI components
supabase/
  functions/              Secure Xendit invoice and webhook functions
  migrations/             Supabase database migrations
android/
  app/                    Android configuration and launcher assets
```

## Prerequisites

Before running the project, install:

- Flutter SDK 3.44 or compatible
- Dart SDK 3.12.2 or newer within the project constraint
- Android Studio and Android SDK
- Firebase CLI
- Supabase CLI
- Node.js, if using Firebase CLI or Supabase tooling

Confirm Flutter is ready:

```powershell
flutter doctor
```

## First-Time Setup

### 1. Clone the repository

```powershell
git clone https://github.com/meowloaf/beckyskitchen.git
cd beckyskitchen
flutter pub get
```

### 2. Configure Firebase

Place the Firebase Android configuration file at:

```text
android/app/google-services.json
```

The existing Firebase project uses:

```text
becky-s-kitchen-e-commerce
```

### 3. Configure client environment values

Copy the example file:

```powershell
Copy-Item .env.example .env
```

Add your public Supabase values to `.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

The `.env` file is ignored by Git. Never add private keys to this file.

Run the app using the environment file:

```powershell
flutter run --dart-define-from-file=.env
```

## Supabase and Xendit Setup

Supabase service-role credentials, Xendit credentials, and webhook secrets belong in **Supabase Edge Function secrets** - never in Flutter, `.env.example`, or the APK.

### Create the database

Push the migration:

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_ID
supabase db push
```

### Set backend secrets

```powershell
supabase secrets set SUPABASE_URL=""
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=""
supabase secrets set XENDIT_SECRET_KEY=""
supabase secrets set XENDIT_CALLBACK_TOKEN=""
```

The `XENDIT_CALLBACK_TOKEN` must match the verification token configured in the Xendit webhook settings.

### Deploy the Edge Functions

```powershell
supabase functions deploy create-xendit-invoice
supabase functions deploy xendit-webhook
```

Register the webhook endpoint in Xendit using:

```text
https://YOUR_PROJECT_ID.supabase.co/functions/v1/xendit-webhook
```

## Firestore Setup

Deploy the security rules:

```powershell
firebase login
firebase deploy --only firestore:rules --project becky-s-kitchen-e-commerce
```

### Grant admin access

1. Create or sign in to a user account in the app.
2. Copy the user's UID from Firebase Authentication.
3. In Firestore, create this document:

```text
admins/{USER_UID}
```

4. Add the field:

| Field | Type | Value |
|---|---|---|
| `enabled` | Boolean | `true` |

Delete the document or change `enabled` to `false` to revoke admin access.

> Admin controls are convenience UI. Firestore security rules are the real authorization boundary.

## Run the App

Development:

```powershell
flutter run --dart-define-from-file=.env
```

Check for issues:

```powershell
flutter analyze
```

## Build a Release APK

```powershell
flutter build apk --release --dart-define-from-file=.env
```

The release APK will be generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Security Notes

- `.env` contains local configuration and is excluded from Git.
- Publishable Supabase keys are intended for client applications.
- Supabase service-role and Xendit secret keys must stay server-side.
- Never commit signing keystores, `key.properties`, service-account files, or private API tokens.
- Production order totals should be validated by a trusted backend before fulfillment.

## Payment Flow

```text
Flutter app
    -> Supabase create-xendit-invoice function
    -> Xendit creates an invoice
    -> Customer completes payment
    -> Xendit sends a webhook
    -> Supabase webhook function updates payment records
```

## Contributing

1. Create a new branch
2. Make focused changes
3. Run `flutter analyze`
4. Test the affected user and admin flows
5. Open a pull request

## License

Add your preferred license before publishing the project publicly.
