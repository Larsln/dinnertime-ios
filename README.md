# Dinnertime for iOS

Native iOS client for the self-hosted Dinnertime server. Every household runs its
own server; the app asks for its address on first launch and talks to nothing else.

- Browse, search and filter recipes by course, tag and favorites, scale
  ingredients to the servings you need
- Create, edit and delete recipes with ingredients, steps, tools and a cover photo
- Import recipes from links, in the app or through the share sheet of TikTok,
  Instagram, Safari and other apps, with live progress and a notification
  about the outcome
- Plan the week, by hand or in three steps: choose days and meals, set
  preferences, then lock or re-roll the proposals before they are saved
- Shopping list in package sizes as large tiles, grouped by the areas of the
  store; changes of other devices show within a second
- Rate recipes with stars in half steps and mark favorites
- Pantry with expiry dates
- Review of the values the server suggests for new products, and editors for
  all products with their package sizes and unit conversions and for the tools

The app is written in SwiftUI and Swift 6 and has no third-party dependencies.
The interface is available in English and German.

## Requirements

- Xcode 26 or later
- iOS 18 or later
- A running Dinnertime server
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), only when the project
  structure changes

Servers outside the local network must be reachable over HTTPS. Plain HTTP is
accepted for `localhost`, IP addresses and `.local` names only.

## Build

The Xcode project is checked in and opens without further steps:

```sh
open Dinnertime.xcodeproj
```

On the command line:

```sh
xcodebuild -scheme Dinnertime -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -scheme Dinnertime -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
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

`Config/Shared.xcconfig` holds the display name, the bundle identifier, the
Keychain group and the App Group. If you change the bundle identifier, the
share extension and both groups follow.

The app and the share extension belong to the App Group
`group.<bundle identifier>`. With automatic signing Xcode registers the group
for your team on the first build with `-allowProvisioningUpdates`; with manual
signing add it to both App IDs in the developer account.

## Layout

| Folder | Target | Content |
|---|---|---|
| `App` | `Dinnertime` | SwiftUI views and view models, one folder per area |
| `ShareExtension` | `ShareExtension` | Share sheet extension that queues imports |
| `Kit` | `DinnertimeKit` | Framework shared by both: API client, endpoints, models, formatting, Keychain, OpenID Connect, the offline copy and the queue of changes |
| `KitTests` | `DinnertimeKitTests` | Unit tests of the framework with recorded API answers |
| `Config` | | Build settings |
| `Scripts` | | Maintenance scripts |

All user-facing text lives in the `Localizable.xcstrings` catalog of its target.

## Working offline

The app keeps a copy of the household's data on the device and shows every
screen from it. The copy is filled by `GET /sync`, which only reports what
changed since the last run, so large collections are never loaded twice.

- **Reading:** `Kit/Offline` answers the calls of the screens from the copy,
  in the shape the server would answer them.
- **Writing:** a change is applied to the copy at once and put into a queue on
  disk with an `Idempotency-Key` and the time the user acted. The queue is
  sent in order whenever the server can be reached. The server lets the later
  action win; a change it turns away is dropped and the copy is brought back
  to the state of the server.
- **Needs the server:** importing a link, proposals for the plan, creating or
  refreshing the shopping list and merging products or tools. A link pasted
  or shared without a connection waits and is submitted later.
- **Images:** every cover is downloaded once and kept.
- **In the shop:** while the shopping list is on screen, phones of the
  household nearby exchange check marks and manual items directly over
  MultipeerConnectivity. They recognise each other by a secret the server
  hands out with the sync; it never leaves the device in the clear.

Signing out deletes the copy, the queue and the images.

## Product icons

The line icons on the shopping list come from the server repository,
`resources/icons/products`. After that directory changed, regenerate the
asset catalog and the manifest in the app:

```sh
Scripts/import-product-icons.py ../backend/resources/icons/products
```

`App/Resources/ProductIcons-LICENSE.md` names the sources and licenses of the
drawings.

## How the share extension gets its credentials

After sign-in the app stores the server address and the API token as one item
in the Keychain. The item belongs to the access group
`$(AppIdentifierPrefix)$(KEYCHAIN_GROUP)`, which both the app and the share
extension list in their entitlements. The extension reads the item, sends the
shared link to `POST /imports` and follows the import. The credentials are
never kept in `UserDefaults`; the App Group only holds the transfers that wait
for imports and the list of imports whose outcome the share sheet showed.

The shared group requires a signed build. Without a development team there is
no application identifier prefix; the app then uses its private Keychain and
the share extension reports that nobody is signed in.

## Notifications about imports

The share sheet shows an import until it is finished. If it is closed
earlier, a background transfer of the share extension keeps waiting at
`GET /imports/{id}/wait`. It writes into the container of the App Group, so
the system hands its answer to the app, which posts a local notification
about the imported recipe or the reason the import failed. No push server is
involved. The app asks for the permission on the recipe list after sign-in;
without it everything else works the same.

## Single sign-on

If the server offers OpenID Connect, the sign-in screen shows a second button.
The app runs the authorization code flow with PKCE in the system browser and
exchanges the ID token at the server. Register the redirect URI
`dinnertime://oidc` for the client at your provider.

## UI tests on a device

The scheme `DinnertimeUITests` drives the installed app against a real
server: it signs in, visits every tab, opens a recipe with its method and its
editor, opens the editor of a product and shares a page from Safari to the
share extension. Nothing is saved. Screenshots are attached to the test result.
The tests are skipped unless the server and account are given:

```sh
TEST_RUNNER_DINNERTIME_SERVER=http://192.168.1.10:8000 \
TEST_RUNNER_DINNERTIME_USERNAME=demo \
TEST_RUNNER_DINNERTIME_PASSWORD=secret \
TEST_RUNNER_DINNERTIME_SHARE_URL=https://example.org/a-recipe \
xcodebuild test -scheme DinnertimeUITests \
    -destination 'platform=iOS,name=My iPhone' -allowProvisioningUpdates
```

The device needs Developer Mode and must be unlocked. The share test expects
the app to be signed in already, so run the walkthrough first.
