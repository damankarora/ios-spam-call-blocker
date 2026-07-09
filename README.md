# Call Blocker

Native iOS app that blocks every phone number in the range **+91 1409-000000**
through **+91 1409-999999** using Apple's `CXCallDirectoryProvider` (Call
Directory Extension) API. No third-party services involved — the block list
lives entirely on-device inside CallKit's own data store.

## How it works

- `CallDirectoryExtension/CallDirectoryHandler.swift` registers 1,000,000
  blocking entries (`911409000000` … `911409999999`, ascending `Int64`,
  country code + digits, no `+`/dashes — required by the API) with CallKit.
- `CallBlockerApp` is a thin container app with one screen: it shows whether
  the extension is enabled, links to Settings, and has a **Reload Blocklist**
  button that calls
  `CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier:)`
  so you can re-push the list after any change to the handler.
- Blocked numbers do **not** show up in Settings → Phone → Blocked Contacts.
  The only visible UI is the toggle at
  **Settings → Phone → Call Blocking & Identification → CallBlocker**.

## Prerequisites

- A Mac with Xcode installed (not just Command Line Tools).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the `.xcodeproj` is
  generated from `project.yml` rather than committed, since hand-edited/
  merged `.pbxproj` files are fragile.
  ```sh
  brew install xcodegen
  ```
- A physical iPhone + USB cable. Call Directory Extensions do not run
  meaningfully in the Simulator — you must test on a device.
- An Apple ID signed into Xcode. A **free personal team** is enough (no paid
  Apple Developer Program required) — see the caveat below.

## Build & run

```sh
git clone https://github.com/damankarora/ios-spam-call-blocker.git
cd ios-spam-call-blocker
xcodegen generate
open CallBlocker.xcodeproj
```

In Xcode:

1. Select the **CallBlocker** target → *Signing & Capabilities* → set your
   Team (your personal Apple ID team) and confirm the bundle identifier
   `com.damankarora.callblocker` is unique to your account (change the
   `bundleIdPrefix` in `project.yml` and regenerate if Xcode complains about
   a collision).
2. Select the **CallDirectoryExtension** target → *Signing & Capabilities* →
   set the same Team. Its bundle ID must be the app's ID with a suffix, e.g.
   `com.damankarora.callblocker.CallDirectoryExtension` (already set).
3. Plug in your iPhone, select it as the run destination, and press **Run**
   on the **CallBlocker** scheme. Trust the developer certificate on-device
   if prompted (Settings → General → VPN & Device Management).

## Enabling the block list

1. On your iPhone: **Settings → Phone → Call Blocking & Identification**.
2. Turn on the **CallBlocker** toggle.
3. Open the CallBlocker app and tap **Reload Blocklist** to push the initial
   1,000,000-entry list into CallKit. This can take a little while the first
   time — the button shows a spinner until it completes.
4. Whenever you change the blocked range in `CallDirectoryHandler.swift`,
   rebuild and re-run, then tap **Reload Blocklist** again (or toggle the
   extension off/on in Settings) to push the update.

## Free Apple Developer team caveats

- Apps signed with a free personal team expire after **7 days** and must be
  re-run from Xcode (or re-signed) to keep working — including the
  extension's blocking data, which Apple may clear when the app is
  reinstalled/re-signed. Re-run from Xcode weekly, or pay for the $99/yr
  Apple Developer Program for 1-year signing validity.
- Free-team provisioning can only install to devices registered to that
  Apple ID — no TestFlight/App Store distribution without the paid program.

## Adjusting the blocked range

Edit the `prefix` and `count` constants in
`CallDirectoryExtension/CallDirectoryHandler.swift`. Entries **must** be
added in strictly ascending order or CallKit silently discards the entire
batch — keep any edits monotonic.

## Project layout

```
project.yml                          XcodeGen spec (source of truth for the Xcode project)
CallBlockerApp/                      Container app (SwiftUI)
  CallBlockerApp.swift
  ContentView.swift
  Assets.xcassets/
CallDirectoryExtension/              Call Directory Extension target
  CallDirectoryHandler.swift
```
