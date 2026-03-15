# Changelog

All notable changes to LiveCaptionsXR are documented here.

## 1.0.50 (2026-03-14)

- Android 15+ compatibility: 16KB memory page size support (PR #116)
- Native library loading fix: `useLegacyPackaging = false` for direct APK native lib mapping
- Closes #109

## 1.0.49 (2026-02-24)

- Fix: Android 16KB memory page size support (PR #116)
- `useLegacyPackaging = false` in `build.gradle.kts` — ensures native libs are uncompressed and 16KB-aligned in APK for Android 15+ devices

## 1.0.48

- Add HuggingFace token support and enhance model download management (PR #110)
- Add consumer guide for Samsung Galaxy XR (PR #111)
- Implement Nexa SDK integration using nexa_ai_flutter package (PR #114)
- Add Nexa SDK integration analysis for Qualcomm bounty program (PR #113)
