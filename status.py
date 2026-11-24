"""Read a small projection of the local ModemManager status."""
import json
from pathlib import Path
import re
import subprocess

MMCLI = Path("/usr/bin/mmcli")
WWAN = Path("/sys/class/wwan")
MODEM_PATH = re.compile(r"^/org/freedesktop/ModemManager1/Modem/\d+$")
SIM_PATH = re.compile(r"^/org/freedesktop/ModemManager1/SIM/\d+$")


def query(*arguments):
    result = subprocess.run([str(MMCLI), *arguments, "--output-json"],
                            capture_output=True, timeout=5, check=True)
    return json.loads(result.stdout)


def label(value):
    if not isinstance(value, str) or value == "--":
        return ""
    return "".join(character for character in value[:100] if character.isprintable()).strip()


def describe(modem, sim):
    generic = modem.get("generic", {})
    cellular = modem.get("3gpp", {})
    lock = label(generic.get("unlock-required"))
    if SIM_PATH.fullmatch(label(generic.get("sim"))) or lock in ("sim-pin", "sim-puk"):
        sim_status = "present"
    elif generic.get("state-failed-reason") == "sim-missing":
        sim_status = "unconfirmed"
    else:
        sim_status = "unknown"

    return {
        "mode": "service",
        "model": label(generic.get("model")),
        "sim": sim_status,
        "operator": label(sim.get("properties", {}).get("operator-name"))
            or label(cellular.get("operator-name")),
        "state": label(generic.get("state")),
        "network": label(cellular.get("registration-state")),
        "lock": lock,
    }


def current():
    xmm = any(WWAN.glob("wwan*xmmrpc*"))
    fallback = {
        "mode": "missing" if xmm or any(WWAN.glob("wwan*")) else "no-modem",
        "sim": "unknown",
        "model": "Intel XMM7360" if xmm else "",
    }
    if not MMCLI.is_file():
        return fallback

    try:
        entries = query("-L").get("modem-list", [])
        modem_path = next((path for path in entries if isinstance(path, str)
                           and MODEM_PATH.fullmatch(path)), None)
        if not modem_path:
            return fallback

        modem = query("-m", modem_path)["modem"]
        sim_path = label(modem.get("generic", {}).get("sim"))
        sim = {}
        if SIM_PATH.fullmatch(sim_path):
            try:
                sim = query("-i", sim_path).get("sim", {})
            except (OSError, ValueError, subprocess.SubprocessError):
                pass
        return describe(modem, sim)
    except (OSError, ValueError, KeyError, TypeError, AttributeError, subprocess.SubprocessError):
        return {**fallback, "mode": "status-error"}


if __name__ == "__main__":
    print(json.dumps(current()))
