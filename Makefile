SHELL := /bin/bash

.PHONY: clean deps build_macos build_windows gen watch test

clean:
	@fvm flutter clean

deps:
	@fvm flutter pub get

gen:
	@fvm flutter pub run build_runner build --delete-conflicting-outputs

watch:
	@fvm flutter pub run build_runner watch --delete-conflicting-outputs

build_macos:
	@fvm flutter build macos

build_windows:
	@fvm flutter build windows

test:
	@fvm flutter test
