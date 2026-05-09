#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")/.."

POD_TAG="${1:?usage: Scripts/test_cocoapods_integration.sh <pod-tag>}"
POD_GIT_URL="${LOOKINSIDE_POD_GIT_URL:-https://github.com/LookInsideApp/LookInside-Release.git}"
WORKDIR="${LOOKINSIDE_COCOAPODS_E2E_DIR:-$(mktemp -d /tmp/lookinside-cocoapods-e2e.XXXXXX)}"
APP_NAME="LookInsideCocoaPodsE2E"

mkdir -p "$WORKDIR/$APP_NAME"
cd "$WORKDIR"

cat >Podfile <<EOF
platform :ios, '13.0'
use_frameworks!

install! 'cocoapods', :deterministic_uuids => false

target '$APP_NAME' do
  pod 'LookInsideServer',
      :git => '$POD_GIT_URL',
      :tag => '$POD_TAG',
      :configurations => ['Debug']
end
EOF

cat >"$APP_NAME/AppDelegate.swift" <<'EOF'
import UIKit
import LookInsideServer

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        _ = LookInsideServer.isLicensed

        let window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
EOF

cat >"$APP_NAME/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>UIApplicationSceneManifest</key>
  <dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
  </dict>
</dict>
</plist>
EOF

ruby <<'RUBY'
require "xcodeproj"

app_name = "LookInsideCocoaPodsE2E"
project = Xcodeproj::Project.new("#{app_name}.xcodeproj")
target = project.new_target(:application, app_name, :ios, "13.0")

group = project.new_group(app_name, app_name)
source = group.new_file("AppDelegate.swift")
target.add_file_references([source])

project.build_configurations.each do |configuration|
  configuration.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
end

target.build_configurations.each do |configuration|
  configuration.build_settings["CODE_SIGNING_ALLOWED"] = "NO"
  configuration.build_settings["CODE_SIGNING_REQUIRED"] = "NO"
  configuration.build_settings["INFOPLIST_FILE"] = "#{app_name}/Info.plist"
  configuration.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "13.0"
  configuration.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "app.lookinside.cocoapods-e2e"
  configuration.build_settings["SWIFT_VERSION"] = "5.9"
  configuration.build_settings["TARGETED_DEVICE_FAMILY"] = "1,2"
end

project.save
RUBY

pod install

build_cmd=(
  xcodebuild
  -workspace "$APP_NAME.xcworkspace"
  -scheme "$APP_NAME"
  -configuration Debug
  -destination "generic/platform=iOS Simulator"
  CODE_SIGNING_ALLOWED=NO
  build
)

if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  "${build_cmd[@]}" 2>&1 | xcbeautify --disable-logging
else
  "${build_cmd[@]}"
fi

echo "CocoaPods integration fixture built at $WORKDIR"
