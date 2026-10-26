# Required Google Play updates

Starting with version 1.0.10 (build 16), Android checks Google Play at launch and when returning to the foreground. Every eligible newer Play version is required; there is no Later or Skip action.

- A short initial check covers all app routes, including the media viewer and dialogs.
- If Play reports a newer version, the target version is saved in app-private preferences before an immediate update is requested.
- Cancelling, failing, restarting the app, opening Google Play, or losing connectivity does not clear a known requirement. Only verifying an installed version at least as new as the recorded target clears it.
- If immediate installation is unavailable, Update now opens the app's Google Play listing. Returning from the store triggers a fresh version check.
- A failed initial Play check without an existing requirement allows the offline media app to remain usable. A failed check never clears a known requirement.
- iOS, web, and desktop do not use this Android update flow.

## Rollout limits

Versions 1.0.9 (15) and earlier do not contain this feature and cannot acquire it remotely. Users must install build 16 or later once. Subsequent eligible releases can then trigger the mandatory update flow. Google Play decides availability for the signed app, user account, device, and release track; a rollout unavailable to that user cannot be forced by the app.

The app still has no Android INTERNET permission. Google Play performs update networking in its own process. See the Google Play [In-App Updates data safety disclosure](https://developer.android.com/guide/playcore/in-app-updates#data-safety).

## Verification before broad release

Unit and widget tests cover latching, cancellation, failures, restart, installation verification, and navigation blocking. A normal debug or sideloaded build cannot establish Play Store eligibility.

For end-to-end testing, use [Google's internal app sharing procedure](https://developer.android.com/guide/playcore/in-app-updates/test): install a build containing this feature through internal app sharing, upload a higher version code, open the newer sharing link without installing it, and reopen the installed older build. Verify cancellation, retry, returning from Google Play, process restart, and successful installation. Both builds must use the same package and the appropriate Play signing identity.

Do not claim Google Play end-to-end verification until that test has been performed.
