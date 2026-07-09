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
