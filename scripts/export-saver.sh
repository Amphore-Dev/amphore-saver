#!/usr/bin/env bash
# Exports one saver as a standalone Xcode project (ScreensaverCore + its Kit
# + its wrapper), used to sync the MacOS/ folder of the per-saver
# repositories (kinogrida-screensaver, Shades-screensaver,
# psykala-screensaver).
#
#   scripts/export-saver.sh <Kinogrida|Shades|Psykala> <destination>
#
# The destination must not exist yet.
set -euo pipefail

name="${1:-}"
dest="${2:-}"
case "$name" in
    Kinogrida) resources='' ;;
    Shades)    resources=', resources: [.copy("Resources/Remained.ttf")]' ;;
    Psykala)   resources=', resources: [.copy("Resources/Artworks")]' ;;
    *) echo "usage: $0 <Kinogrida|Shades|Psykala> <destination>" >&2; exit 1 ;;
esac
if [ -z "$dest" ] || [ -e "$dest" ]; then
    echo "destination must be given and must not exist: '$dest'" >&2
    exit 1
fi

root="$(cd "$(dirname "$0")/.." && pwd)"
kit="${name}Kit"
lower="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
revision="$(git -C "$root" rev-parse --short HEAD)"
version="$(sed -n 's/.*MARKETING_VERSION: "\(.*\)"/\1/p' "$root/project.yml")"

mkdir -p "$dest/Sources" "$dest/Saver"
cp -R "$root/Sources/ScreensaverCore" "$root/Sources/$kit" "$dest/Sources/"
cp "$root/Savers/$name/${name}SaverView.swift" "$dest/Saver/"
cp -R "$root/Savers/$name/Resources" "$dest/Saver/"

# The package keeps the "amphore-saver" name: resource bundles are looked up
# as amphore-saver_<Kit>.bundle.
cat > "$dest/Package.swift" <<EOF
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "amphore-saver",
    platforms: [.macOS("11.5")],
    products: [
        .library(name: "ScreensaverCore", targets: ["ScreensaverCore"]),
        .library(name: "$kit", targets: ["$kit"]),
    ],
    targets: [
        .target(name: "ScreensaverCore"),
        .target(name: "$kit", dependencies: ["ScreensaverCore"]$resources),
    ]
)
EOF

cat > "$dest/project.yml" <<EOF
name: $name

options:
  bundleIdPrefix: com.amphore-dev
  deploymentTarget:
    macOS: "11.5"
  createIntermediateGroups: true

packages:
  AmphoreKit:
    path: .

settings:
  base:
    SWIFT_VERSION: "6.0"
    MARKETING_VERSION: "$version"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: JTV45F2TPG
    CODE_SIGN_STYLE: Manual
    CODE_SIGN_IDENTITY: "-"
    ENABLE_HARDENED_RUNTIME: YES
    WRAPPER_EXTENSION: saver
    GENERATE_INFOPLIST_FILE: YES
    INFOPLIST_KEY_NSHumanReadableCopyright: "Copyright © 2026 Amphore Dev. MIT License."
    SKIP_INSTALL: YES
  configs:
    Release:
      ONLY_ACTIVE_ARCH: NO

targets:
  $name:
    type: bundle
    platform: macOS
    sources:
      - path: Saver
    settings:
      PRODUCT_NAME: $name
      PRODUCT_BUNDLE_IDENTIFIER: com.amphore-dev.amphore-saver.$lower
      INFOPLIST_KEY_NSPrincipalClass: ${name}SaverView
    dependencies:
      - package: AmphoreKit
        products: [ScreensaverCore, $kit]
EOF

# Same targets as the monorepo Makefile, for a single saver.
sed -e "s/^PROJECT .*/PROJECT        = $name.xcodeproj/" \
    -e "s/^SCHEMES .*/SCHEMES        = $name/" \
    -e "s/^SAVERS .*/SAVERS         = $name/" \
    -e '/make install SAVER=/d' \
    "$root/Makefile" > "$dest/Makefile"

cat > "$dest/.gitignore" <<'EOF'
*.xcodeproj/
.build/
.swiftpm/
build/
dist/
EOF

cat > "$dest/README.md" <<EOF
# $name — macOS

Generated from [amphore-saver](https://github.com/Amphore-Dev/amphore-saver) \`$revision\` (v$version) by \`scripts/export-saver.sh\`.
Do not edit here: change amphore-saver and export again.

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (\`brew install xcodegen\`).

\`\`\`bash
make            # generate $name.xcodeproj and build $name.saver
make install    # build + install to ~/Library/Screen Savers
make remove     # uninstall
make release    # sign (Developer ID), notarize and staple into dist/
\`\`\`
EOF

echo "Exported $name ($revision) to $dest"
