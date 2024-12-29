#!/bin/bash

set -e
if [[ $* == *--scriptdebug* ]]; then
    set -x
fi

cd "$(dirname "$0")"

WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=QuickSign
PLATFORM=iOS
SDK=iphoneos
if [[ $* == *--debug* ]]; then
    TARGET=Debug
else
    TARGET=Release
fi

# xcbeautify/xcpretty
if [[ $* == *--scriptdebug* ]]; then
    XCBEAUTIFY="cat"
elif command -v xcbeautify > /dev/null; then
    XCBEAUTIFY="xcbeautify --disable-logging"
elif command -v xcpretty > /dev/null; then
    XCBEAUTIFY="xcpretty"
else
    XCBEAUTIFY="cat"
fi


echo "[*] Deleting previous packages..."
rm -rf "build/$APPLICATION_NAME.ipa"
rm -rf "build/$APPLICATION_NAME.tipa"
rm -rf "build/Payload"

if [[ $* == *--clean* ]]; then
    echo "[*] Deleting build folder..."
    rm -rf "build"
fi

echo "[*] Building $APPLICATION_NAME ($TARGET)..."

if [ ! -d "build" ]; then
    mkdir build
fi

cd build

if [[ $* == *--clean* ]]; then
    xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
        -scheme "$APPLICATION_NAME" \
        -configuration "$TARGET" \
        -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
        -destination "generic/platform=$PLATFORM" \
        clean build \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
        | $XCBEAUTIFY
else
    xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
        -scheme "$APPLICATION_NAME" \
        -configuration "$TARGET" \
        -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
        -destination "generic/platform=$PLATFORM" \
        clean build \
        CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
        | $XCBEAUTIFY
fi

DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/"$TARGET"-$SDK/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

echo "[*] Removing code signature"
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# Add entitlements
#echo "[*] Adding entitlements"
#ldid -S"$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.entitlements" "$TARGET_APP/$APPLICATION_NAME"
#
#ldid -S"$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.entitlements" "$TARGET_APP/PlugIns/AmpereIntents.appex/AmpereIntents"
#
#ldid -S"$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.entitlements" "$TARGET_APP/PlugIns/AmpereWidgetExtension.appex/AmpereWidgetExtension"

#echo "[*] Building Daemons..."
#cd $WORKING_LOCATION/TrollRecorder
#if ! type "gmake" > /dev/null; then
#    echo "[!] gmake not found, using macOS bundled make instead"
#    make clean
#    if [[ $* == *--debug* ]]; then
#    make
#    else
#    make FINALPACKAGE=1
#    fi
#else
#    gmake clean
#    if [[ $* == *--debug* ]]; then
#    gmake -j"$(sysctl -n machdep.cpu.thread_count)"
#    else
#    gmake -j"$(sysctl -n machdep.cpu.thread_count)" FINALPACKAGE=1
#    fi
#fi
#
#if [[ $* == *--debug* ]]; then
#    cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/debug/audio-mixer" "$TARGET_APP/recall-audio-mixer"
#        cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/debug/audio-recorder" "$TARGET_APP/recall-audio-recorder"
#            cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/debug/call-monitor" "$TARGET_APP/recall-call-monitor"
#else
#    cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/audio-mixer" "$TARGET_APP/recall-audio-mixer"
#        cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/audio-recorder" "$TARGET_APP/recall-audio-recorder"
#            cp "$WORKING_LOCATION/TrollRecorder/.theos/obj/call-monitor" "$TARGET_APP/recall-call-monitor"
#fi
#
#cd -

echo "[*] Packaging..."
mkdir Payload
cp -r $APPLICATION_NAME.app Payload/$APPLICATION_NAME.app

if [[ $* != *--debug* ]]; then
strip Payload/$APPLICATION_NAME.app/$APPLICATION_NAME
fi


ZIP_ARGS=""

if [[ $* == *--scriptdebug* ]]; then
ZIP_ARGS="-rv"
else
ZIP_ARGS="-r"
fi

if [[ $* == *--tipa* ]]; then
zip $ZIP_ARGS $APPLICATION_NAME.tipa Payload
else
zip $ZIP_ARGS $APPLICATION_NAME.ipa Payload
fi

rm -rf $APPLICATION_NAME.app
rm -rf Payload
