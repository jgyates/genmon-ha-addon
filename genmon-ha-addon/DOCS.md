# Genmon

Runs [genmon](https://github.com/jgyates/genmon) on the Home Assistant machine.

## Web UI

- **Sidebar panel (ingress):** click **Genmon** in the sidebar. Home Assistant handles the login.
- **Direct access:** `http://<home-assistant-ip>:8000/`. Set a genmon username and password if this port is reachable from untrusted devices.

Genmon's HTTPS option is turned off on every start because ingress only works over plain HTTP. Passkeys only work on the direct port.

## Connecting to the generator

Choose one of these:

1. **USB-RS485 adapter (easiest):** plug it in, then select it under **Serial port** in the app configuration.
2. **Raspberry Pi GPIO UART (pins 14/15):** add one line (Pi 5) or two lines (Pi 3/4) at the end of `config.txt` on the HAOS boot partition, reboot, then select the device under **Serial port**:
   - Pi 5: add `dtparam=uart0=on` and use `/dev/ttyAMA0`. (`/dev/ttyAMA10` is the separate debug connector, not the GPIO pins.)
   - Pi 3/4: add `enable_uart=1` and `dtoverlay=disable-bt` and use `/dev/ttyAMA0`.

   Edit the file either on a computer (SD card/SSD removed; on Windows a Pi 5 disk needs a drive letter assigned with `diskpart` first, and the boot partition is always partition 1), or on the Pi with the Advanced SSH & Web Terminal app (protection mode off) and a one-line `docker run` command. SSH apps cannot see the boot partition directly, and `raspi-config` does not exist on Home Assistant OS. Step-by-step instructions and the commands for each Pi model: [README – Raspberry Pi GPIO serial port](https://github.com/jgyates/genmon-ha-addon#2-raspberry-pi-gpio-serial-port-pins-1415).

   On a Pi 5 with an M.2 HAT+, the HAT covers the GPIO header. It is connected only through its PCIe ribbon cable, so it can be mounted underneath the Pi instead.
3. **Serial over TCP / Modbus TCP:** enable **Use serial over TCP** and enter the converter's address and port. Also enable **Modbus TCP** if the converter speaks Modbus TCP (port usually `502`) rather than plain serial passthrough. No local device is needed.

App options are written to `genmon.conf` only when they are set. Leave them empty to manage these settings from the genmon web UI.

If the configured serial port does not exist, the app sets the genmon serial port to a placeholder (`/run/genmon/no-serial-port`) so genmon and its web UI still start (showing communication errors). Set the real port in the genmon web UI under **Settings** and save; genmon restarts and uses it.

## Moving from an existing genmon install

1. On the old genmon: **About** → **Export Configuration** (older versions: `sudo ~/genmon/genmonmaint.sh -b`). This creates `genmon_backup.tar.gz` with all settings and the outage log, service journal and kW/fuel logs.
2. In the app's genmon web UI: **About** → **Import Configuration** (up to 10 MB).
3. Restart the app, then set the serial port for this machine (the imported one, e.g. `/dev/serial0`, usually doesn't exist here).

Details: [README – Moving from an existing genmon install](https://github.com/jgyates/genmon-ha-addon#moving-from-an-existing-genmon-install).

## Files

- Configuration and history (outage log, service journal, kW/fuel logs): `/data/genmon/` (kept across restarts and updates, included in HA backups and genmon's Export/Import Configuration)
- Logs: `/data/log/` (genmon, genserv and genloader logs are also shown in the app log)

## Differences from a normal genmon install

| Web UI action | Behavior in this app |
|---|---|
| Update | Not supported. Update the app instead. |
| Reboot | Restarts the app, not the host. |
| Shutdown | Stops the app, not the host. |
| Restart | Restarts genmon inside the app. |

Not supported: Bluetooth (Mopeka), GPIO add-ons, SPI/I²C add-ons (CT sensor HAT, DIY fuel tank gauge), the LTE modem add-on.
