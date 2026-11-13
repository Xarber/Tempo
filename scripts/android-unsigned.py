# SPDX-License-Identifier: AGPL-3.0-only
"""Remove the generated Expo debug signing binding from release builds."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text()
updated, count = re.subn(
    r"(\n\s+release \{(?:\n\s*//[^\n]*)*\n)\s*signingConfig signingConfigs\.debug\n",
    r"\1",
    source,
)
if count != 1:
    raise SystemExit("Expected one debug signing binding in the release block.")
path.write_text(updated)
