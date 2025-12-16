
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

# Debug: Show the structure of the iOS archive
echo "=== iOS Archive Structure ==="
ls -la build/AdgeistKit-iOS.xcarchive/Products/ || true
ls -la build/AdgeistKit-iOS.xcarchive/Products/Library/ || true
ls -la build/AdgeistKit-iOS.xcarchive/Products/Library/Frameworks/ || true

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

# Debug: Show the structure of the Simulator archive
echo "=== Simulator Archive Structure ==="
ls -la build/AdgeistKit-iOS_Simulator.xcarchive/Products/ || true
ls -la build/AdgeistKit-iOS_Simulator.xcarchive/Products/Library/ || true
ls -la build/AdgeistKit-iOS_Simulator.xcarchive/Products/Library/Frameworks/ || true

# Determine the correct framework paths
IOS_FRAMEWORK_PATH=""
SIM_FRAMEWORK_PATH=""

# Check for framework in different possible locations
if [ -d "build/AdgeistKit-iOS.xcarchive/Products/Library/Frameworks/AdgeistKit.framework" ]; then
    IOS_FRAMEWORK_PATH="build/AdgeistKit-iOS.xcarchive/Products/Library/Frameworks/AdgeistKit.framework"
elif [ -d "build/AdgeistKit-iOS.xcarchive/Products/usr/local/lib/AdgeistKit.framework" ]; then
    IOS_FRAMEWORK_PATH="build/AdgeistKit-iOS.xcarchive/Products/usr/local/lib/AdgeistKit.framework"
else
    echo "ERROR: Cannot find iOS framework"
    find build/AdgeistKit-iOS.xcarchive -name "AdgeistKit.framework" -type d
    exit 1
fi

if [ -d "build/AdgeistKit-iOS_Simulator.xcarchive/Products/Library/Frameworks/AdgeistKit.framework" ]; then
    SIM_FRAMEWORK_PATH="build/AdgeistKit-iOS_Simulator.xcarchive/Products/Library/Frameworks/AdgeistKit.framework"
elif [ -d "build/AdgeistKit-iOS_Simulator.xcarchive/Products/usr/local/lib/AdgeistKit.framework" ]; then
    SIM_FRAMEWORK_PATH="build/AdgeistKit-iOS_Simulator.xcarchive/Products/usr/local/lib/AdgeistKit.framework"
else
    echo "ERROR: Cannot find Simulator framework"
    find build/AdgeistKit-iOS_Simulator.xcarchive -name "AdgeistKit.framework" -type d
    exit 1
fi

echo "Using iOS framework: $IOS_FRAMEWORK_PATH"
echo "Using Simulator framework: $SIM_FRAMEWORK_PATH"

# Convert the archives to .framework
# and package them both into one xcframework
xcodebuild \
    -create-xcframework \
    -framework "$IOS_FRAMEWORK_PATH" \
    -framework "$SIM_FRAMEWORK_PATH" \
    -output output/AdgeistKit.xcframework &&\
    rm -rf build
