.PHONY: generate watch test translations firebase-android talkback fontsize

generate:
	fvm dart run build_runner build --delete-conflicting-outputs

watch:
	fvm dart run build_runner watch --delete-conflicting-outputs

test: 
	echo $(VAR)

clean:
	fvm flutter clean

get: 
	fvm flutter pub get

translations:
	fvm dart run easy_localization:generate --source-dir ./assets/translations --output-dir lib/l10n
	fvm dart run easy_localization:generate -f keys -o locale_keys.g.dart --source-dir ./assets/translations --source-file de.json --output-dir lib/l10n

icons:
	dart pub global activate icon_font_generator && generator assets/input_svg_icons_dont_use_directly/ assets/fonts/purelei_icons_font.otf --output-class-file=lib/common/ui/purelei_icons.dart -r --class-name=PureleiIcons --font-name=PureleiIcons

firebase-android:
	fvm flutter build apk && cd android && bundle install && bundle exec fastlane distribute_firebase_app groups:${GROUPS} && cd ..

talkback:
	if adb shell settings get secure touch_exploration_enabled | grep -q "1"; then adb shell settings put secure enabled_accessibility_services "com.pleco.chinesesystem/com.pleco.chinesesystem.ScreenContentCaptureService"; adb shell settings put secure touch_exploration_enabled 0; echo "TalkBack OFF"; else adb shell settings put secure enabled_accessibility_services "com.pleco.chinesesystem/com.pleco.chinesesystem.ScreenContentCaptureService:com.samsung.android.accessibility.talkback/com.samsung.android.marvin.talkback.TalkBackService"; adb shell settings put secure accessibility_enabled 1; adb shell settings put secure touch_exploration_enabled 1; echo "TalkBack ON"; fi

fontsize:
	adb shell settings put system font_scale ${SIZE}

flavor-dev:
	flutterfire config --project=purelei-app-dev --out=lib/firebase_options_dev.dart --ios-bundle-id=com.tapcart.9qz7aMTAGC --ios-out=ios/flavors/dev/GoogleService-Info.plist --android-package-name=co.tapcart.app.id_9qz7aMTAGC --android-out=android/app/src/dev/google-services.json

flavor-prod:
	flutterfire config --project=purelei-app-prod --out=lib/firebase_options_prod.dart --ios-bundle-id=com.tapcart.05tlfl98He --ios-out=ios/flavors/prod/GoogleService-Info.plist --android-package-name=co.tapcart.app.id_05tlfl98He --android-out=android/app/src/prod/google-services.json

appbundle-dev:
	fvm flutter build appbundle --flavor dev