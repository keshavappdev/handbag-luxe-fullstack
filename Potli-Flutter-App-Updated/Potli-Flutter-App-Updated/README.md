# POTLI Flutter customer app

This is the supplied Potli app integrated with the included Node/MongoDB backend. See `../README.md` for complete setup and device configuration.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1/
```

The default URL targets an Android emulator. Use localhost for an iOS simulator or your computer's LAN address for a phone. Keep the final `/`. Release builds require HTTPS. JWTs are stored using flutter_secure_storage.

Firebase is optional and off by default. Configure your own project and add `--dart-define=ENABLE_FIREBASE=true` when testing push. For Google authentication, configure your OAuth clients and `GOOGLE_SERVER_CLIENT_ID` as documented in the root README.

Products and inventory are managed in React admin; do not add products to Flutter source. This package has passed Dart syntax parsing, but not a complete analyzer/device build in the delivery environment. See `../docs/VERIFICATION.md`.


## Firebase configuration

This source package intentionally ships with placeholder Firebase values. Firebase startup is disabled by default. Before using push notifications or other Firebase features, run `flutterfire configure` for your own Potli Firebase project, replace the generated native configuration files, and build with `--dart-define=ENABLE_FIREBASE=true`.
