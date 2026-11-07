#!/bin/zsh
# SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
cd "$(dirname "$0")/.."
configuration="${1:-debug}"
sdk_args=()
if [[ -n "${TEMPO_SDK:-}" ]]; then sdk_args=(--sdk "$TEMPO_SDK"); fi
swift build -c "$configuration" "${sdk_args[@]}"
binary_dir="$(swift build -c "$configuration" "${sdk_args[@]}" --show-bin-path)"
variant="${TEMPO_VARIANT:-Tempo}"
if [[ "$variant" != Tempo && "$variant" != TempoQA ]]; then print -u2 "Unsupported variant; choose Tempo or TempoQA"; exit 1; fi
app="${TEMPO_OUTPUT_DIR:-build}/$variant.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary_dir/Tempo" "$app/Contents/MacOS/Tempo"
commit="$(git rev-parse --verify HEAD 2>/dev/null || echo development)"
if [[ -n "$(git status --porcelain)" ]]; then commit="$commit-dirty"; fi
cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.openrecode.${variant:l}</string>
<key>CFBundleExecutable</key><string>Tempo</string>
<key>CFBundleName</key><string>Tempo</string>
<key>CFBundleDisplayName</key><string>Tempo</string>
<key>CFBundleIconFile</key><string>Tempo</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>TempoDataNamespace</key><string>$variant</string>
<key>TempoCommit</key><string>$commit</string>
</dict></plist>
PLIST
if [[ -f build/Tempo.icns ]]; then cp build/Tempo.icns "$app/Contents/Resources/Tempo.icns"; fi
codesign --force --deep --sign - "$app"
print "Built $app ($commit); local ad-hoc signature, not notarized."
