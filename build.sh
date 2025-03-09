#!/bin/sh

set -e

# Get version
version=$(xcodebuild -showBuildSettings | grep MARKETING_VERSION | awk '{print $3}')

# Build xcode project
xcodebuild -project wenigwarden.xcodeproj \
	-scheme wenigwarden \
	ARCHS=arm64 \
	-destination "platform=macOS,arch=arm64" \
	-configuration Release \
	CODE_SIGN_IDENTITY="-" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO \
	PROVISIONING_PROFILE="" \
	CONFIGURATION_BUILD_DIR="$(pwd)/build/Release"

codesign --force --deep --sign - "$(pwd)/build/Release/Wenigwarden.app"

# Sign Sparkle
current_dir=$(pwd)
cd "$(pwd)/build/Release/Wenigwarden.app/Contents/Frameworks"
codesign -f -s - -o runtime Sparkle.framework/Versions/B/XPCServices/Installer.xpc
codesign -f -s - -o runtime --preserve-metadata=entitlements Sparkle.framework/Versions/B/XPCServices/Downloader.xpc
codesign -f -s - -o runtime Sparkle.framework/Versions/B/Autoupdate
codesign -f -s - -o runtime Sparkle.framework/Versions/B/Updater.app
codesign -f -s - -o runtime Sparkle.framework
cd "$current_dir"

# Create dmg
dmgpath="build/Release/wenigwarden-$version.dmg"
rm "$dmgpath" || true
appdmg appdmg.json "$dmgpath"

# Generate sparkple signature
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
PROJECT_PATH=$(find "$DERIVED_DATA" -name "wenigwarden-*" -type d -maxdepth 1)
"$PROJECT_PATH/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update" "$dmgpath"
