# Mealplanner for iOS

Native iOS client for the self-hosted Mealplanner server. Every household runs its
own server; the app asks for its address on first launch and talks to nothing else.

- Browse and search recipes, scale ingredients to the servings you need
- Import recipes from links, in the app or through the share sheet of TikTok,
  Instagram, Safari and other apps
- Plan the week, by hand or generated so that opened packages are used up
- Shopping list in package sizes, grouped by the areas of the store
- Pantry with expiry dates
- Review of the values the server suggests for new products

The app is written in SwiftUI and Swift 6 and has no third-party dependencies.
The interface is available in English and German.

## Requirements

- Xcode 26 or later
- iOS 18 or later
- A running Mealplanner server
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), only when the project
  structure changes

Servers outside the local network must be reachable over HTTPS. Plain HTTP is
accepted for `localhost`, IP addresses and `.local` names only.

## Build

The Xcode project is checked in and opens without further steps:

```sh
open Mealplanner.xcodeproj
```

On the command line:

```sh
xcodebuild -scheme Mealplanner -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -scheme Mealplanner -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

The project is generated from `project.yml`. After adding, moving or removing
files, or after changing build settings, regenerate it and commit the result:

```sh
brew install xcodegen
xcodegen generate
```

## Signing

Settings that differ per developer live in `Config/Local.xcconfig`, which git
ignores. Create it with your team:

```
DEVELOPMENT_TEAM = ABCDE12345
```

`Config/Shared.xcconfig` holds the display name, the bundle identifier and the
Keychain group. If you change the bundle identifier, the share extension and
the Keychain group follow.

## Layout

| Folder | Target | Content |
|---|---|---|
| `App` | `Mealplanner` | SwiftUI views and view models, one folder per area |
| `ShareExtension` | `ShareExtension` | Share sheet extension that queues imports |
| `Kit` | `MealplannerKit` | Framework shared by both: API client, endpoints, models, formatting, Keychain, OpenID Connect |
| `KitTests` | `MealplannerKitTests` | Unit tests of the framework with recorded API answers |
| `Config` | | Build settings |

All user-facing text lives in the `Localizable.xcstrings` catalog of its target.

## How the share extension gets its credentials

After sign-in the app stores the server address and the API token as one item
in the Keychain. The item belongs to the access group
`$(AppIdentifierPrefix)$(KEYCHAIN_GROUP)`, which both the app and the share
extension list in their entitlements. The extension reads the item, sends the
shared link to `POST /imports` and closes. Nothing is kept in `UserDefaults`
except the server address used last, and no App Group is needed.

The shared group requires a signed build. Without a development team there is
no application identifier prefix; the app then uses its private Keychain and
the share extension reports that nobody is signed in.

## Single sign-on

If the server offers OpenID Connect, the sign-in screen shows a second button.
The app runs the authorization code flow with PKCE in the system browser and
exchanges the ID token at the server. Register the redirect URI
`mealplanner://oidc` for the client at your provider.

## UI tests on a device

The scheme `MealplannerUITests` drives the installed app against a real
server: it signs in, visits every tab, opens a recipe and shares a page from
Safari to the share extension. Screenshots are attached to the test result.
The tests are skipped unless the server and account are given:

```sh
TEST_RUNNER_MEALPLANNER_SERVER=http://192.168.1.10:8000 \
TEST_RUNNER_MEALPLANNER_USERNAME=demo \
TEST_RUNNER_MEALPLANNER_PASSWORD=secret \
TEST_RUNNER_MEALPLANNER_SHARE_URL=https://example.org/a-recipe \
xcodebuild test -scheme MealplannerUITests \
    -destination 'platform=iOS,name=My iPhone' -allowProvisioningUpdates
```

The device needs Developer Mode and must be unlocked. The share test expects
the app to be signed in already, so run the walkthrough first.
