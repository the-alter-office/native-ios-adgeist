
# A shell script for creating an XCFramework for iOS.

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
        -workspace native-ios-adgeist.xcworkspace \
        -scheme AdgeistKit \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -archivePath build/AdgeistKit-iOS.xcarchive \
         -sdk iphoneos

# Create an archive for iOS simulators
xcodebuild \
    archive \
        ONLY_ACTIVE_ARCH=NO \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        -workspace native-ios-adgeist.xcworkspace \
        -scheme AdgeistKit \
        -configuration Release \
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
