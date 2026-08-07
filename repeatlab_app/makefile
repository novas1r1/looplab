.PHONY: generate watch clean get cleanget fontsize appbundle \
	devices doctor run run-driver logs screenshot

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

appbundle:
	fvm flutter build appbundle --release

# --- Device / emulator ------------------------------------------------------
# See docs/device_testing.md for the full "run it and check it" loop.

devices:
	fvm flutter devices

doctor:
	fvm flutter doctor -v

# Run the app in debug mode. Pass DEVICE=<id> to pick a target.
run:
	fvm flutter run $(if $(DEVICE),-d $(DEVICE),)

# Run the app with the Flutter Driver extension so tooling can drive it
# (tap/scroll/enter text/read the widget tree). See test_driver/app.dart.
run-driver:
	fvm flutter run -t test_driver/app.dart $(if $(DEVICE),-d $(DEVICE),)

# Tail the Android device log, filtered to Flutter output.
logs:
	adb logcat -s flutter:V

# Capture the connected Android device screen to build/screenshots/.
# Pass NAME=<name> to control the file name.
screenshot:
	@mkdir -p build/screenshots
	adb shell screencap -p /sdcard/repeatlab_screen.png
	adb pull /sdcard/repeatlab_screen.png build/screenshots/$(if $(NAME),$(NAME),screen).png
	adb shell rm /sdcard/repeatlab_screen.png
