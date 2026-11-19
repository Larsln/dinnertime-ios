#!/bin/sh
# Archives the app and uploads it to App Store Connect for TestFlight.
# Needs the development team in Config/Local.xcconfig and an Apple account
# with access to the app signed in to Xcode. Raise CURRENT_PROJECT_VERSION
# in Config/Shared.xcconfig before every upload.
set -eu

cd "$(dirname "$0")/.."
work="${TMPDIR:-/tmp}/dinnertime-release"
team="$(sed -n 's/^DEVELOPMENT_TEAM *= *//p' Config/Local.xcconfig)"

rm -rf "$work"
mkdir -p "$work"
xcodegen

xcodebuild archive -scheme Dinnertime -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$work/Dinnertime.xcarchive" -allowProvisioningUpdates

cat > "$work/options.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>$team</string>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive -archivePath "$work/Dinnertime.xcarchive" \
    -exportPath "$work/export" -exportOptionsPlist "$work/options.plist" \
    -allowProvisioningUpdates
