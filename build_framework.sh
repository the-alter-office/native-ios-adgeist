
# A shell script for creating an XCFramework for iOS.
# configuration: Release (default), Beta, QA, or Prod

# Get configuration from argument, default to Release
CONFIGURATION="${1:-Release}"

echo "🔨 Building AdgeistKit XCFramework with configuration: $CONFIGURATION"

# Starting from a clean slate
# Removing the build and output folders
rm -rf ./build &&\
rm -rf ./output &&\

# Cleaning the workspace cache
xcodebuild \
    clean \
    -workspace native-ios-adgeist.xcworkspace \
    -scheme AdgeistKit

# Create an archive for iOS devices
xcodebuild \
    archive \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        -workspace native-ios-adgeist.xcworkspace \
        -scheme AdgeistKit \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS" \
        -archivePath build/AdgeistKit-iOS.xcarchive \
         -sdk iphoneos

# Create an archive for iOS simulators
xcodebuild \
    archive \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        -workspace native-ios-adgeist.xcworkspace \
        -scheme AdgeistKit \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS Simulator" \
        -archivePath build/AdgeistKit-iOS_Simulator.xcarchive \
        -sdk iphonesimulator

# Convert the archives to .framework
# and package them both into one xcframework
xcodebuild \
    -create-xcframework \
    -framework build/AdgeistKit-iOS.xcarchive/Products/Library/Frameworks/AdgeistKit.framework \
    -framework build/AdgeistKit-iOS_Simulator.xcarchive/Products/Library/Frameworks/AdgeistKit.framework \
    -output output/AdgeistKit.xcframework &&\
    rm -rf build
