# MMB – Mumbai Mobile Bazar

Two Flutter apps (Riverpod + Firebase) sharing one core package.

```
mmb/
├── firebase/            firestore.rules, storage.rules
├── packages/mmb_core/   models, theme, auth, validators, shared widgets
├── mmb_seller/          Distributor app
└── mmb_buyer/           Buyer / retailer app
```

## 1. Setup
1. Install Flutter (3.22+). From this folder run `bash setup.sh` – it creates the
   `android/` and `ios/` folders for both apps and runs `flutter pub get`.
2. Create a Firebase project. Enable **Authentication → Email/Password**, **Cloud Firestore**
   and **Storage** (Storage needs the Blaze plan).
3. Register one Android + iOS app per Flutter app in Firebase
   (package names: `com.mmb.mmb_seller`, `com.mmb.mmb_buyer`) and add
   `google-services.json` → `<app>/android/app/` and `GoogleService-Info.plist` → `<app>/ios/Runner/`.
   (Or run `flutterfire configure` in each app.) Follow Firebase's Gradle plugin steps for Android.
4. Deploy the rules: `firebase deploy --only firestore:rules,storage`
   (copy `firebase/firestore.rules` and `firebase/storage.rules` into your firebase project if needed).

## 2. Launcher permissions (call + WhatsApp buttons)
**Android** – in `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` (outside `<application>`):
```xml
<queries>
  <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
</queries>
```
**iOS** – in `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array><string>tel</string><string>https</string><string>whatsapp</string></array>
<key>NSPhotoLibraryUsageDescription</key><string>Pick product photos</string>
```
(Add the photo key to the seller app only.)

## 3. Approving users (until the admin panel exists)
* **Distributor approval:** Firestore → `users/{uid}` → set `status` to `approved`.
  Sellers register as `pending` and cannot post until then.
* **Product approval:** Firestore → `products/{id}` → set `status` to `approved`.
  It then appears in the Buyer app automatically. Set `featured: true` to show it under "Trending".
* **Admin role (future panel):** give an account the custom claim `admin: true` with the Firebase
  Admin SDK. The rules already allow admins full access.
* Optional content: add docs to `banners` (`title`, `subtitle`, `imageUrl`, `active`, `order`) and
  `categories` (`name`, `active`, `order`). Apps fall back to built-in defaults when empty.

## 4. Privacy model
* Every product stores `sellerId` = the creator's Firebase uid.
* The Seller app only queries `where sellerId == uid`, and the Firestore rules reject any read,
  update or delete of another seller's product – even from a modified app.
* Buyers can only read products with `status == approved`.
* Users cannot change their own `role` or `status`; products cannot be self-approved.

## 5. Notes / next steps
* Login is Email + Password. Phone OTP can be added in `AuthRepository`.
* A seller's profile edits apply to new/edited products (contact details are copied onto each product).
* Buyer filtering/search runs in-memory on approved products – fine for thousands of items;
  move to Algolia/Typesense or indexed queries when the catalogue grows.
* Checkout is an enquiry flow (no payments). One enquiry is created per seller.
* Not yet verified by compiling: run `flutter analyze` in each app after setup.
