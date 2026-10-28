# beckyskitchen

A new Flutter project.

Admin access is managed with an `admins/{uid}` document in Firestore. The
Firestore rules allow admins to manage products and orders, but prevent app
users from granting themselves admin access.

## Give an account admin access

1. **Create and sign in to the account** in the app.
2. In Firebase Console, open **Authentication → Users** and copy that
   account's UID.
3. Open **Firestore Database → Data**, create a collection named `admins`,
   then create a document whose document ID is the account's UID. Add this field:

   | Field | Type | Value |
   |---|---|---|
   | `enabled` | boolean | `true` |

4. **Deploy the Firestore rules** from this repository if you have not already.
   Install the Firebase CLI, sign in, and deploy:

   ```sh
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules --project becky-s-kitchen-e-commerce
   ```

5. Return to the app and open the **Profile** tab. The admin controls should
   appear; the app watches this document for changes.

To revoke access, delete the user's document from the `admins` collection or set
`enabled` to `false`. Only trusted project administrators should edit this
collection in the Firebase Console; app users are explicitly denied writes.

The rules allow public product reads, restrict product changes and order
management to admins, and limit customers to creating and reading their own
orders. Hiding admin controls in the app is not a security boundary.

Order records are submitted by the customer app. These rules restrict who can
create and read them, but they cannot verify that submitted item prices and
totals match the current product catalog. For paid orders or automatic
fulfillment, calculate and validate order totals in a trusted backend before
treating them as authoritative.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
