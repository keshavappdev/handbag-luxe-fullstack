# Potli migration audit

- Customer-facing and native branding updated to **Potli**.
- Android namespace/applicationId: `com.potli.app`.
- iOS bundle identifier: `com.potli.app`.
- Firebase files contain non-production placeholder values only; Firebase remains opt-in through `ENABLE_FIREBASE`.
- Secure token key renamed to `potli_api_token`.
- Potli credit endpoint constant renamed to `get_my_potli_credits` to satisfy the zero-legacy-brand requirement. The backend must expose this route (or an alias) for that feature to work.
- All bundled imagery was replaced with newly generated original luxury handbag artwork, and Dart asset references were updated to the new filenames.
