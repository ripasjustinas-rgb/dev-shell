"""Instantiate the real media component with a fake player; never plays audio."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MediaUiTests(unittest.TestCase):
    @unittest.skipUnless(shutil.which("qs") and os.environ.get("WAYLAND_DISPLAY"), "Quickshell and Wayland are required")
    def test_absolute_relative_and_unsupported_seeking(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory)
            for name in ("components", "services", "theme"):
                shutil.copytree(ROOT / "dotfiles/.config/quickshell/laptopui" / name, config / name)
            shutil.copy(ROOT / "tests/media-smoke.qml", config / "shell.qml")
            # No visible window or notification server, no persisted preferences.
            result = subprocess.run(["qs", "-p", directory, "--no-color"], capture_output=True,
                                    text=True, timeout=15, env={**os.environ, "QT_QPA_PLATFORM": "wayland"})
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("MEDIA_SMOKE_PASSED", output)
            self.assertNotIn("TypeError", output)
            self.assertNotIn("ReferenceError", output)


if __name__ == "__main__":
    unittest.main()
