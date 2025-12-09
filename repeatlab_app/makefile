.PHONY: generate watch test translations firebase-android talkback fontsize

generate:
	fvm dart run build_runner build --delete-conflicting-outputs

watch:
	fvm dart run build_runner watch --delete-conflicting-outputs

clean:
	fvm flutter clean

get: 
	fvm flutter pub get

cleanget:
	make clean && make get

fontsize:
	adb shell settings put system font_scale ${SIZE}

appbundle-dev:
	fvm flutter build appbundle