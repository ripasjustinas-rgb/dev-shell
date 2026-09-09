"""Bounded regression tests; no live network probes or desktop mutations."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
HELPERS = ROOT / "dotfiles/.local/bin"
source = (HELPERS / "laptopui-network-info").read_text().split("<<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
network = {}
exec(compile(source.split("\nmode = ", 1)[0], "laptopui-network-info", "exec"), network)


class NetworkTests(unittest.TestCase):
    def test_escaped_colons_and_trailing_backslash(self):
        self.assertEqual(network["fields"](r"Home\: Office\\:vpn"), ["Home: Office\\", "vpn"])

    def test_offline_does_not_query_wifi_or_probe_internet(self):
        calls = []
        def run(args, timeout=4):
            calls.append(args)
            return "[]"
        with patch.dict(network, run=run):
            info = network["snapshot"]()
        self.assertEqual(info["interface"], "")
        self.assertTrue(all(args[0] == "ip" for args in calls))

    def test_ipv6_only_route(self):
        def run(args, timeout=4):
            if args[:3] == ["ip", "-j", "-6"]:
                return json.dumps([{"dev": "test0", "src": "2001:db8::2", "gateway": "fe80::1"}])
            return "[]" if args[0] == "ip" else ""
        with patch.dict(network, run=run):
            info = network["snapshot"]()
        self.assertEqual(info["interface"], "test0")
        self.assertEqual(info["address"], "2001:db8::2")

    def test_wifi_rate_is_not_mislabeled_as_negotiated_link_speed(self):
        def run(args, timeout=4):
            if args[0] == "ip":
                return '[{"dev":"test0","prefsrc":"192.0.2.2"}]'
            if "GENERAL,IP4,IP6" in args:
                return "GENERAL.TYPE:wifi\nGENERAL.CONNECTION:Home\\: Office"
            if "NAME,TYPE" in args:
                return "Tunnel\\: Work:vpn"
            if "wifi" in args:
                return "yes:Home\\: Office:80:5240 MHz:48:1170 Mbit/s:WPA2"
            return ""
        with patch.dict(network, run=run):
            info = network["snapshot"]()
        self.assertEqual(info["wifi"]["ssid"], "Home: Office")
        self.assertEqual(info["vpn"], ["Tunnel: Work"])
        self.assertNotIn("linkSpeed", info)
        self.assertEqual(info["wifi"]["apRate"], "1170 Mbit/s")

    def test_failed_probes_are_not_reported_as_internet_success(self):
        with patch.dict(network, run=lambda *args: "", snapshot=lambda: {"gateway": "192.0.2.1"}):
            result = network["diagnose"]()["result"]
        self.assertIn("no ICMP reply", result)
        self.assertIn("resolution failed", result)
        self.assertIn("HTTPS probe failed", result)

    def test_missing_command_and_timeout_return_empty(self):
        self.assertEqual(network["run"](["/nonexistent/laptopui-test-command"]), "")
        self.assertEqual(network["run"](["sleep", "1"], timeout=0.01), "")


class VisualizerTests(unittest.TestCase):
    def test_restart_drops_stale_tail(self):
        with tempfile.TemporaryDirectory() as directory:
            temporary = Path(directory)
            state = temporary / "laptopui-visualizer"
            state.mkdir()
            output = state / "spectrum.txt"
            output.write_text("old frame\n" * 1000)
            fake_cava = temporary / "cava"
            fake_cava.write_text("""#!/usr/bin/env python3
import pathlib, sys
config = pathlib.Path(sys.argv[2]).read_text()
target = next(line.split(' = ', 1)[1] for line in config.splitlines() if line.startswith('raw_target = '))
with open(target, 'r+') as stream:
    stream.write('1;2;3;4;\\n')
""")
            fake_cava.chmod(0o755)
            env = {**os.environ, "XDG_RUNTIME_DIR": directory, "PATH": directory + ":" + os.environ["PATH"]}
            subprocess.run([str(HELPERS / "laptopui-visualizer-daemon")], env=env, check=True, timeout=3)
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and output.read_text() != "1;2;3;4;\n":
                time.sleep(0.02)
            self.assertEqual(output.read_text(), "1;2;3;4;\n")


if __name__ == "__main__":
    unittest.main()
