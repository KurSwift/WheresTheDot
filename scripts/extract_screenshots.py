#!/usr/bin/env python3
"""
extract_screenshots.py
Extract XCTAttachment screenshots from an .xcresult bundle using xcresulttool.

Usage: python3 extract_screenshots.py <xcresult-path> <output-dir>
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile


def extract(xcresult_path, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        result = subprocess.run(
            [
                "xcrun", "xcresulttool", "export", "attachments",
                "--path", xcresult_path,
                "--output-path", tmp,
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print(f"  ERROR: xcresulttool failed: {result.stderr.strip()}", file=sys.stderr)
            return 0

        manifest_path = os.path.join(tmp, "manifest.json")
        if not os.path.exists(manifest_path):
            print("  ERROR: No manifest.json in result bundle", file=sys.stderr)
            return 0

        with open(manifest_path) as f:
            manifest = json.load(f)

        count = 0
        # Strip the trailing _<index>_<UUID> that Xcode appends to the suggested name.
        _suffix_re = re.compile(r"_\d+_[0-9A-Fa-f-]{36}(\.[^.]+)$")

        for entry in manifest:
            for attachment in entry.get("attachments", []):
                src = os.path.join(tmp, attachment["exportedFileName"])
                suggested = attachment.get("suggestedHumanReadableName", attachment["exportedFileName"])
                clean_name = _suffix_re.sub(r"\1", suggested)
                dst = os.path.join(output_dir, clean_name)
                if os.path.exists(src):
                    shutil.copy2(src, dst)
                    count += 1

        return count


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <xcresult-path> <output-dir>")
        sys.exit(1)

    n = extract(sys.argv[1], sys.argv[2])
    print(f"  Extracted {n} screenshot(s)")
