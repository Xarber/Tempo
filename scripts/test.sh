#!/bin/zsh
# SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -n "${TEMPO_SDK:-}" && "$(xcode-select -p)" == /Library/Developer/CommandLineTools ]]; then
    # Apple's preview CLT default build system omits the Testing macro plugin.
    swift test --build-system native --sdk "$TEMPO_SDK" -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks
else
    swift test
fi
