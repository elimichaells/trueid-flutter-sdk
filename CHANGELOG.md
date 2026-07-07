## 1.1.0

* Added `TrueIdSdk.launchHostedVerification()` — document capture + selfie with
  liveness, review, and result via TrueID's hosted flow in a Chrome Custom Tab.
  Same UI/UX as the TrueID web widget and hosted component.
* Native dependency: switched primary Android repo from JitPack to the
  self-hosted TrueID Maven repo (`https://app.trueid.info/sdk/android`),
  matching `trueid-selfie-sdk` 2.3.0. JitPack kept as a fallback.

## 1.0.0

* Initial release
* End-to-end identity verification (PIN + selfie + NIA)
* Standalone selfie capture with face detection
* Activity Result API and callback support
* ML Kit face alignment with visual guidance
