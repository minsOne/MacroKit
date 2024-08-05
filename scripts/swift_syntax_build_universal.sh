#!/bin/bash

SWIFT_SYNTAX_VERSION=$1
SWIFT_SYNTAX_NAME="swift-syntax"
SWIFT_SYNTAX_REPOSITORY_URL="https://github.com/apple/$SWIFT_SYNTAX_NAME.git"
SEMVER_PATTERN="^[0-9]+\.[0-9]+\.[0-9]+$"
WRAPPER_NAME="SwiftSyntaxWrapper"
ARCH="arm64"
CONFIGURATION="debug"

# Common modules for both platforms
SWIFT_SYNTAX_MODULES=(
    "SwiftBasicFormat"
    "SwiftCompilerPlugin"
    "SwiftCompilerPluginMessageHandling"
    "SwiftDiagnostics"
    "SwiftOperators"
    "SwiftParser"
    "SwiftParserDiagnostics"
    "SwiftSyntax"
    "SwiftSyntaxBuilder"
    "SwiftSyntaxMacroExpansion"
    "SwiftSyntaxMacros"
    "SwiftSyntaxMacrosTestSupport"
    "_SwiftSyntaxTestSupport"
    "$WRAPPER_NAME"
)

# Additional modules for macOS
MACOS_ADDITIONAL_MODULES=(
    "SwiftIDEUtils"
    "SwiftRefactor"
)

# Combine common and macOS-specific modules
MACOS_MODULES=("${SWIFT_SYNTAX_MODULES[@]}" "${MACOS_ADDITIONAL_MODULES[@]}")

# iOS Simulator modules (same as common modules in this case)
IOS_SIMULATORS_MODULES=("${SWIFT_SYNTAX_MODULES[@]}")

#
# Verify input
#

if [ -z "$SWIFT_SYNTAX_VERSION" ]; then
    echo "Swift syntax version (git tag) must be supplied as the first argument"
    exit 1
fi

if ! [[ $SWIFT_SYNTAX_VERSION =~ $SEMVER_PATTERN ]]; then
    echo "The given version ($SWIFT_SYNTAX_VERSION) does not have the right format (expected X.Y.Z)."
    exit 1
fi

#
# Print input
#

cat << EOF

Input:
swift-syntax version to build:  $SWIFT_SYNTAX_VERSION

EOF

set -eux

#
# Clone package
#

git clone --branch $SWIFT_SYNTAX_VERSION --single-branch $SWIFT_SYNTAX_REPOSITORY_URL

#
# Add static wrapper product
#

sed -i '' -E "s/(products: \[)$/\1\n    .library(name: \"${WRAPPER_NAME}\", type: .static, targets: [\"${WRAPPER_NAME}\"]),/g" "$SWIFT_SYNTAX_NAME/Package.swift"

#
# Add target for wrapper product
#

sed -i '' -E "s/(targets: \[)$/\1\n    .target(name: \"${WRAPPER_NAME}\", dependencies: [\"SwiftCompilerPlugin\", \"SwiftSyntax\", \"SwiftSyntaxBuilder\", \"SwiftSyntaxMacros\", \"SwiftSyntaxMacrosTestSupport\"]),/g" "$SWIFT_SYNTAX_NAME/Package.swift"

#
# Add exported imports to wrapper target
#

WRAPPER_TARGET_SOURCES_PATH="$SWIFT_SYNTAX_NAME/Sources/$WRAPPER_NAME"

mkdir -p $WRAPPER_TARGET_SOURCES_PATH

tee $WRAPPER_TARGET_SOURCES_PATH/ExportedImports.swift <<EOF
@_exported import SwiftCompilerPlugin
@_exported import SwiftSyntax
@_exported import SwiftSyntaxBuilder
@_exported import SwiftSyntaxMacros
EOF

#
# Build the wrapper
#

mkdir -p Outputs/macos-arm64 Outputs/macos-x86_64 Outputs/macos-arm64_x86_64 Outputs/iOS-Simulator-arm64

for ARCH in arm64 x86_64; do
    swift build --package-path "$SWIFT_SYNTAX_NAME" --arch "$ARCH" -c "$CONFIGURATION" -Xswiftc -enable-library-evolution -Xswiftc -emit-module-interface
    cp "$SWIFT_SYNTAX_NAME/.build/$ARCH-apple-macosx/$CONFIGURATION/lib$WRAPPER_NAME.a" "Outputs/macos-$ARCH/lib$WRAPPER_NAME.a"
done

lipo -create -output Outputs/macos-arm64_x86_64/lib$WRAPPER_NAME.a Outputs/macos-arm64/lib$WRAPPER_NAME.a Outputs/macos-x86_64/lib$WRAPPER_NAME.a

for MODULE in ${MACOS_MODULES[@]}; do
    cp "$SWIFT_SYNTAX_NAME/.build/arm64-apple-macosx/${CONFIGURATION}/${MODULE}.build/${MODULE}.swiftinterface" "Outputs/macos-arm64_x86_64"
done

(
    cd $SWIFT_SYNTAX_NAME && \
    xcodebuild clean archive \
        -scheme $WRAPPER_NAME \
        -configuration $CONFIGURATION \
        -destination "generic/platform=iOS Simulator" \
        -derivedDataPath build/ios-simulator \
        -archivePath "./XCFrameworkArchives/ios_simulators.xcarchive"  \
        ARCHS=arm64 \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO
)

ar -crs Outputs/iOS-Simulator-arm64/lib$WRAPPER_NAME.a $SWIFT_SYNTAX_NAME/XCFrameworkArchives/ios_simulators.xcarchive/Products/Users/**/Objects/*.o

for MODULE in ${IOS_SIMULATORS_MODULES[@]}; do
    PATH_TO_INTERFACE="$SWIFT_SYNTAX_NAME/build/ios-simulator/Build/Intermediates.noindex/ArchiveIntermediates/$WRAPPER_NAME/IntermediateBuildFilesPath/$SWIFT_SYNTAX_NAME.build/${CONFIGURATION}-iphonesimulator/${MODULE}.build/Objects-normal/arm64/${MODULE}.swiftinterface"
    cp "${PATH_TO_INTERFACE}" "Outputs/iOS-Simulator-arm64"
done

#
# Create XCFramework
#

XCFRAMEWORK_NAME="$WRAPPER_NAME.xcframework"
xcodebuild -create-xcframework \
  -library Outputs/macos-arm64_x86_64/lib$WRAPPER_NAME.a \
  -library Outputs/iOS-Simulator-arm64/lib$WRAPPER_NAME.a \
  -output Outputs/$XCFRAMEWORK_NAME

#
# Copy SwiftInterface files to XCFramework
#

for MODULE in ${MACOS_MODULES[@]}; do
    PATH_TO_INTERFACE="Outputs/macos-arm64_x86_64/${MODULE}.swiftinterface"
    cp "${PATH_TO_INTERFACE}" "Outputs/SwiftSyntaxWrapper.xcframework/macos-arm64_x86_64"
done

for MODULE in ${IOS_SIMULATORS_MODULES[@]}; do
    PATH_TO_INTERFACE="Outputs/iOS-Simulator-arm64/${MODULE}.swiftinterface"
    cp "${PATH_TO_INTERFACE}" "Outputs/SwiftSyntaxWrapper.xcframework/ios-arm64-simulator"
done

#
# Cleanup
#

mkdir -p XCFramework
mv "Outputs/$WRAPPER_NAME.xcframework" "XCFramework/$WRAPPER_NAME.xcframework"
rm -rf swift-syntax Outputs