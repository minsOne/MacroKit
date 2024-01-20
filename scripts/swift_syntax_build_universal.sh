#!/bin/bash

SWIFT_SYNTAX_VERSION=$1
SWIFT_SYNTAX_NAME="swift-syntax"
SWIFT_SYNTAX_REPOSITORY_URL="https://github.com/apple/$SWIFT_SYNTAX_NAME.git"
SEMVER_PATTERN="^[0-9]+\.[0-9]+\.[0-9]+$"
WRAPPER_NAME="SwiftSyntaxWrapper"
ARCH="arm64"
CONFIGURATION="debug"

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

swift build --package-path $SWIFT_SYNTAX_NAME --arch $ARCH -c $CONFIGURATION -Xswiftc -enable-library-evolution -Xswiftc -emit-module-interface

PATH_TO_LIBRARY_ARM64="$SWIFT_SYNTAX_NAME/.build/$ARCH-apple-macosx/$CONFIGURATION/lib$WRAPPER_NAME.a"

ARCH="x86_64"

swift build --package-path $SWIFT_SYNTAX_NAME --arch $ARCH -c $CONFIGURATION -Xswiftc -enable-library-evolution -Xswiftc -emit-module-interface

PATH_TO_LIBRARY_X86_64="$SWIFT_SYNTAX_NAME/.build/$ARCH-apple-macosx/$CONFIGURATION/lib$WRAPPER_NAME.a"

#
# Create XCFramework
#

lipo -create -output $WRAPPER_NAME.a $PATH_TO_LIBRARY_ARM64 $PATH_TO_LIBRARY_X86_64

XCFRAMEWORK_NAME="$WRAPPER_NAME.xcframework"
xcodebuild -create-xcframework -library $WRAPPER_NAME.a -output $XCFRAMEWORK_NAME

rm $WRAPPER_NAME.a

MODULES=(
    "SwiftBasicFormat"
    "SwiftCompilerPlugin"
    "SwiftCompilerPluginMessageHandling"
    "SwiftDiagnostics"
    "SwiftIDEUtils"
    "SwiftOperators"
    "SwiftParser"
    "SwiftParserDiagnostics"
    "SwiftRefactor"
    "SwiftSyntax"
    "SwiftSyntaxBuilder"
    "SwiftSyntaxMacroExpansion"
    "SwiftSyntaxMacros"
    "SwiftSyntaxMacrosTestSupport"
    "_SwiftSyntaxTestSupport"
    "$WRAPPER_NAME"
)

ARCHS=(
    "x86_64"
    "arm64"
)

for ARCH in ${ARCHS[@]}; do
    for MODULE in ${MODULES[@]}; do
        PATH_TO_INTERFACE="$SWIFT_SYNTAX_NAME/.build/${ARCH}-apple-macosx/${CONFIGURATION}/${MODULE}.build/${MODULE}.swiftinterface"
        cp "${PATH_TO_INTERFACE}" "${XCFRAMEWORK_NAME}/macos-arm64_x86_64"
    done
done

rm -rf swift-syntax
mkdir -p XCFramework
mv $WRAPPER_NAME.xcframework XCFramework/$WRAPPER_NAME.xcframework
