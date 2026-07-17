# Call Blocker

Native iOS app that blocks whole ranges of phone numbers — by default every
number from **+91 1409-000000** through **+91 1409-999999** — using Apple's
`CXCallDirectoryProvider` (Call Directory Extension) API. No third-party
services involved — the block list lives entirely on-device inside CallKit's
own data store.

## Features

- Block entire number ranges (country code + prefix + up to 6 wildcard
  digits) instead of one number at a time.
- Add, edit, and remove ranges from an in-app editor — no rebuild required.
- 100% on-device: no network calls, no analytics, no third-party services.
  The block list never leaves the phone.
- One-tap **Reload Blocklist** to push changes into CallKit.

## Contents

- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Build & run](#build--run)
- [Enabling the block list](#enabling-the-block-list)
- [Free Apple Developer team caveats](#free-apple-developer-team-caveats)
- [Adjusting the blocked ranges](#adjusting-the-blocked-ranges)
- [Project layout](#project-layout)
- [Privacy](#privacy)
- [License](#license)

## How it works

- Blocked ranges are defined as **country code + prefix + number of wildcard
  digits** (e.g. `91`, `1409`, `6` → blocks `911409000000`…`911409999999`)
  and edited from the app's **Blocked Ranges** screen — no rebuild required
  to add/remove/change a range.
- Ranges are stored as JSON in a shared **App Group** `UserDefaults`
  (`Shared/BlockListStore.swift`), since the app and the extension run as
  separate processes and can't talk to each other directly.
- `CallDirectoryExtension/CallDirectoryHandler.swift` reads the saved ranges,
  sorts and de-duplicates them, and registers each number with CallKit in
  strictly ascending `Int64` order (country code + digits, no `+`/dashes —
  required by the API, which silently discards the whole batch otherwise).
- `CallBlockerApp` is a thin container app: one screen shows whether the
  extension is enabled, links to the ranges editor, and has a **Reload
  Blocklist** button that calls
  `CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier:)`
  so you can re-push the list after any change.
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
3. Both targets already declare the `group.com.damankarora.callblocker` App
   Group in their entitlements (via `project.yml`). With automatic signing,
   Xcode registers this App Group on your account the first time you build —
   free personal teams support App Groups, no paid membership needed. If you
   changed `bundleIdPrefix` in `project.yml`, also update the App Group
   identifier in both `entitlements.properties` blocks and in
   `Shared/BlockListStore.swift` (`appGroupID`) so they still match each
   other.
4. Plug in your iPhone, select it as the run destination, and press **Run**
   on the **CallBlocker** scheme. Trust the developer certificate on-device
   if prompted (Settings → General → VPN & Device Management).

## Enabling the block list

1. On your iPhone: **Settings → Phone → Call Blocking & Identification**.
2. Turn on the **CallBlocker** toggle.
3. Open the CallBlocker app. The default range (+91 1409-XXXXXX) is preloaded;
   add/edit/remove ranges from **Blocked Ranges**.
4. Tap **Reload Blocklist** to push the list into CallKit. For a full
   1,000,000-entry range this can take a little while the first time — the
   button shows a spinner until it completes.
5. Whenever you add, remove, or edit a range, tap **Reload Blocklist** again
   (or toggle the extension off/on in Settings) to push the update — no
   rebuild needed.

## Free Apple Developer team caveats

- Apps signed with a free personal team expire after **7 days** and must be
  re-run from Xcode (or re-signed) to keep working — including the
  extension's blocking data, which Apple may clear when the app is
  reinstalled/re-signed. Re-run from Xcode weekly, or pay for the $99/yr
  Apple Developer Program for 1-year signing validity.
- Free-team provisioning can only install to devices registered to that
  Apple ID — no TestFlight/App Store distribution without the paid program.

## Adjusting the blocked ranges

Use the **Blocked Ranges** screen in the app — no rebuild required. Each
range is capped at 6 wildcard digits (1,000,000 numbers), matching Apple's
documented scale for call directory extensions; add multiple ranges if you
need to cover more than one prefix. `CallDirectoryHandler` merges and sorts
all saved ranges into strictly ascending order itself, so overlapping ranges
are handled safely.

## Project layout

```
project.yml                          XcodeGen spec (source of truth for the Xcode project)
CallBlockerApp/                      Container app (SwiftUI)
  CallBlockerApp.swift
  ContentView.swift
  BlockedRangesView.swift            Add/edit/remove blocked ranges
  Assets.xcassets/
CallDirectoryExtension/              Call Directory Extension target
  CallDirectoryHandler.swift
Shared/                              Shared between app and extension (App Group)
  BlockRange.swift                   Country code + prefix + wildcard digits model
  BlockListStore.swift               Reads/writes ranges via shared UserDefaults
```

## Privacy

Call Blocker makes no network requests and includes no analytics or
third-party SDKs. Blocked ranges are stored only in a local, on-device App
Group `UserDefaults` container shared between the app and its extension —
nothing is ever sent off the phone.

## License

No license file is currently included in this repository, so all rights
are reserved by default. Add a `LICENSE` file if you want to permit reuse.
