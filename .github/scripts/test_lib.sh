set -eo pipefail

xcodebuild -workspace Example/CombineAsync.xcworkspace \
            -scheme CombineAsync-Example \
            -destination platform=iOS\ Simulator,OS=15.2,name=iPhone\ 11 \
            clean test | xcpretty