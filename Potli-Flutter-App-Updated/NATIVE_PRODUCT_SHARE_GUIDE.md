# Potli Android product sharing — setup guide

## What changed
- `android/app/src/main/java/com/potli/app/ProductShareHandler.java` — Java Android Share Sheet.
- `android/app/src/main/kotlin/com/potli/app/MainActivity.kt` — registers MethodChannel.
- `lib/services/native_product_share_service.dart` — Dart bridge.
- `lib/views/shop/shop_views.dart` — share icon in product detail AppBar.

This shares product name, shown price and the store homepage, **not** an unverified product detail URL. No extra package or Android permission is needed.

## Run on Android (Windows / VS Code)
1. Install Flutter SDK, Android Studio SDK tools, Java 17 and VS Code Flutter/Dart extensions.
2. Open this Flutter project folder (the one containing `pubspec.yaml`).
3. Start an Android emulator or connect a phone with USB debugging.
4. In VS Code terminal run:

```powershell
flutter doctor
flutter pub get
flutter devices
flutter run
```

5. Open Shop > any product detail page > tap the new share icon beside the heart icon.
6. Select any available share target in the Android chooser.

**Troubleshooting**: if native code changes don't appear, stop app and run `flutter clean`, `flutter pub get`, `flutter run` (hot reload alone will not recompile Java/Kotlin). Existing Firebase/backend/Razorpay configuration remains required for the parts of the original app that depend on them.

## How the bridge works
Dart calls `MethodChannel('com.potli.app/product_share').invokeMethod('shareProduct', {...})`. Kotlin `MainActivity` receives it and forwards to `ProductShareHandler.java`. Android opens `Intent.ACTION_SEND` chooser. Returned success means the chooser was opened, not that sharing was completed.

## iOS
This feature is Android-only for now. On iOS implement the *same* channel/method in `ios/Runner/AppDelegate.swift` using `UIActivityViewController`, or use a cross-platform share plugin. Without this, tapping share on iOS displays the app's `Unable to share this product` snackbar. Do not call the channel on iOS until an iOS handler is added.
