#!/bin/bash

# Script to help add UTM tracking files to Xcode project
# Run this script, then verify in Xcode that files are properly added

echo "🚀 UTM Tracking Files Setup Helper"
echo "===================================="
echo ""

# Check if we're in the right directory
if [ ! -d "AdgeistKit/AdgeistKit.xcodeproj" ]; then
    echo "❌ Error: Must run this script from the native-ios-adgeist root directory"
    exit 1
fi

echo "✅ Found AdgeistKit project"
echo ""

# Check if UTM files exist
UTM_PARAMS="AdgeistKit/AdgeistKit/core/UTMParameters.swift"
UTM_TRACKER="AdgeistKit/AdgeistKit/core/UTMTracker.swift"

if [ -f "$UTM_PARAMS" ]; then
    echo "✅ Found UTMParameters.swift"
else
    echo "❌ Missing UTMParameters.swift"
    exit 1
fi

if [ -f "$UTM_TRACKER" ]; then
    echo "✅ Found UTMTracker.swift"
else
    echo "❌ Missing UTMTracker.swift"
    exit 1
fi

echo ""
echo "📝 Manual Steps Required:"
echo "========================="
echo ""
echo "Since Xcode project files need to be modified carefully, please:"
echo ""
echo "1. Open AdgeistKit.xcodeproj in Xcode"
echo "   $ open AdgeistKit/AdgeistKit.xcodeproj"
echo ""
echo "2. In Xcode Project Navigator:"
echo "   - Right-click on 'AdgeistKit/core' folder"
echo "   - Select 'Add Files to AdgeistKit...'"
echo "   - Navigate to AdgeistKit/AdgeistKit/core/"
echo "   - Select both:"
echo "     • UTMParameters.swift"
echo "     • UTMTracker.swift"
echo "   - UNCHECK 'Copy items if needed' (files are already in place)"
echo "   - Ensure 'AdgeistKit' target is selected"
echo "   - Click 'Add'"
echo ""
echo "3. Build the framework:"
echo "   $ xcodebuild -workspace native-ios-adgeist.xcworkspace -scheme AdgeistKit -configuration Debug"
echo ""
echo "4. (Optional) Build the xcframework:"
echo "   $ ./build_framework.sh"
echo ""
echo "📚 Documentation:"
echo "================="
echo "• Quick Start: UTM_QUICK_START.md"
echo "• Full Guide: UTM_TRACKING_GUIDE.md"
echo "• Implementation: IMPLEMENTATION_SUMMARY.md"
echo ""
echo "🎉 Ready to add UTM tracking to your iOS SDK!"
