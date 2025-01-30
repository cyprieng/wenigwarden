#!/bin/sh

version=$(xcodebuild -showBuildSettings | grep MARKETING_VERSION | awk '{print $3}')

xcodebuild -project wenigwarden.xcodeproj \
	-scheme wenigwarden \
	ARCHS=arm64 \
	-destination "platform=macOS,arch=arm64" \
	-configuration Release CONFIGURATION_BUILD_DIR="$(pwd)/build/Release"

appdmg appdmg.json "build/Release/wenigwarden-$version.dmg"
