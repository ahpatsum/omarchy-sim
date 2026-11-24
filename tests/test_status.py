from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import status


class StatusTest(unittest.TestCase):
    def test_display_only_fields_and_literal_operator_text(self):
        result = status.describe(
            {"generic": {"sim": "/org/freedesktop/ModemManager1/SIM/0",
                         "state": "disabled", "model": "Reference modem", "device-identifier": "private"}},
            {"properties": {"operator-name": "<b>carrier</b>\n", "imsi": "private"}},
        )
        self.assertEqual(result["operator"], "<b>carrier</b>")
        self.assertEqual(result["sim"], "present")
        self.assertEqual(result["model"], "Reference modem")
        self.assertNotIn("private", str(result))
        qml = Path(__file__).resolve().parents[1] / "Panel.qml"
        self.assertNotIn("Text.AutoText", qml.read_text())

    def test_pin_and_missing_sim(self):
        self.assertEqual(status.describe({"generic": {"unlock-required": "sim-pin"}}, {})["sim"],
                         "present")
        self.assertEqual(status.describe({"generic": {"state-failed-reason": "sim-missing"}}, {})["sim"],
                         "unconfirmed")

    def test_xmm_hardware_is_not_sim_detection(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            (path / "wwan0xmmrpc0").touch()
            with patch.object(status, "WWAN", path), patch.object(status, "MMCLI", path / "missing"):
                self.assertEqual(status.current(), {"mode": "missing", "sim": "unknown",
                                                    "model": "Intel XMM7360"})

    def test_only_valid_modem_paths_are_queried(self):
        modem = "/org/freedesktop/ModemManager1/Modem/0"
        with patch.object(status, "MMCLI", Path(__file__)), patch.object(status, "query") as query:
            query.side_effect = [{"modem-list": [None, "/other", modem]}, {"modem": {}}]
            self.assertEqual(status.current()["mode"], "service")
            query.assert_called_with("-m", modem)
