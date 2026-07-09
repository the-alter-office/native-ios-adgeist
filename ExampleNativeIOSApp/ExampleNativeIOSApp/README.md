# Test the SDK locally in another app

CocoaPods supports a local path dependency, so a separate app project can consume this repo's SDK directly off disk — no publishing or git tag required.

1. Build the xcframework from this repo's root:

   ```bash
   ./build_framework.sh
   ```

   This produces `output/AdgeistKit.xcframework`, which is what `AdgeistKit.podspec` vendors. Pass `Beta`, `QA`, or `Prod` as an argument to build a different configuration (default is `Release`), e.g. `./build_framework.sh Beta`.

2. In the other app's `Podfile`, point `AdgeistKit` at this repo's local path instead of the git source, e.g.:

   ```ruby
   pod 'AdgeistKit', :path => '/Users/kishore/Documents/work/sdks/native-ios-adgeist'
   ```

3. Run `pod install` in that app.

4. To pick up further SDK changes: re-run `./build_framework.sh` in this repo, then just rebuild the consumer app — no need to re-run `pod install` unless the podspec itself changed (e.g. a new dependency).
