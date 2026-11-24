# SIM for Omarchy

A free, read-only cellular status widget for the Omarchy shell. Click **SIM** in
the top bar to see the modem model, SIM detection and lock status, carrier, and
network registration. English and French are included.

## Install

```sh
omarchy plugin add https://github.com/ahpatsum/omarchy-sim.git --enable
```

Requires the Omarchy Quattro shell and Python 3. Live SIM status requires a
running ModemManager service that supports your modem. The widget reads the
first modem reported by `mmcli`. It identifies the Intel XMM7360 hardware
without ModemManager, but its SIM status remains unconfirmed until a
ModemManager build with native XMM7360 RPC support is available.
See the [XMM7360 notes](https://wiki.archlinux.org/title/Intel_XMM_7360).

Select **Refresh** or press **R** while the panel is open. Press **Esc** to close
it. Reads happen when the panel opens or when you explicitly refresh it.

## Remove

```sh
omarchy plugin remove tamdintdesign.sim
```

## Data access

The widget uses read-only local `mmcli` queries. Its report contains the modem
model, carrier and status fields. It excludes phone numbers, SIM serial
numbers and subscriber identifiers. It makes no outbound network requests,
starts no mobile data session and requires no administrator privileges.

## Development

```sh
omarchy plugin validate .
python -m unittest discover -s tests
```
