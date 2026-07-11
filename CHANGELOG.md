## 2.0.0

* **BREAKING:** `TrueIdSdk.initialize()` now takes `secretKey` and/or
  `publishableKey` instead of a single `apiKey`. The two keys are not
  interchangeable server-side: `verify()`/`captureSelfie()`/`fastTrackVerify()`
  use the secret key, `launchHostedVerification()` uses the publishable key.
  Migration: `initialize(apiKey: k)` → `initialize(secretKey: k)` (and add
  your publishable key if you use the hosted flow).
* Added `TrueIdSdk.fastTrackVerify()` — re-verify a known individual with a
  fresh live selfie and server-side face match. Your backend supplies the
  `individualId`; capture mode and liveness follow the organization's policy.
* Guided liveness ring now fills toward the side the user is asked to turn,
  and the fill animates smoothly instead of stepping.
* Review screen no longer mirror-flips the captured selfie.
* Native dependency: `trueid-selfie-sdk` bumped to 2.5.0.

## 1.3.0

* Native NIA verification flow rebuilt to exactly match the TrueID field app:
  Photo Instructions screen → selfie capture with guided liveness (turn head
  left/right, return to center, 3-2-1 countdown) → review screen showing the
  captured face where the user enters their Ghana Card PIN (auto-formatted
  `GHA-XXXXXXXXX-X`) and submits. Transient network failures keep the captured
  selfie and allow retrying in place.
* New `VerificationConfig` fields: `requireLiveness` (default true),
  `showGuidelines` (default true), `transactionTypes` (optional dropdown
  choices for the review screen).
* Native verification now reads the institution's `selfieCapture` setting by
  default (`guided`, `manual`, or `auto`). Set
  `useOrganizationCaptureSettings: false` to use local capture settings.
* Native dependency: `trueid-selfie-sdk` bumped to 2.5.0.

## 1.2.0

* Added NFC chip reading: `TrueIdSdk.isNfcSupported()`, `isNfcEnabled()`, and
  `readNfcChip()` — reads the ICAO 9303 chip on Ghana Card / ePassport-style
  documents (BAC/PACE handshake, DG1/DG2/DG7/DG11) given the MRZ key fields
  from a prior camera scan. Android only for now; ported from the NFC engine
  proven out in TrueID's standalone field app so third-party integrators get
  the same capability. There is no browser/widget equivalent — Web NFC cannot
  perform the ISO 7816 APDU exchanges an ICAO 9303 chip requires.
* Native dependency: `trueid-selfie-sdk` bumped to 2.4.0.

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
