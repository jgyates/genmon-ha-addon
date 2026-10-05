# Genmon

Runs [genmon](https://github.com/jgyates/genmon) on the Home Assistant machine.

## Web UI

- **Sidebar panel (ingress):** click **Genmon** in the sidebar. Home Assistant handles the login.
- **Direct access:** `http://<home-assistant-ip>:8000/`. Set a genmon username and password if this port is reachable from untrusted devices.

Genmon's HTTPS option is turned off on every start because ingress only works over plain HTTP. Passkeys only work on the direct port.

## Connecting to the generator

Choose one of these:

1. **USB-RS485 adapter (easiest):** plug it in, then select it under **Serial port** in the app configuration.
2. **Raspberry Pi GPIO UART (pins 14/15):** edit `config.txt` on the HAOS boot partition (put the SD card/SSD in a PC, or use an SSH app with protection mode off: `/mnt/boot/config.txt`), reboot, then select the device under **Serial port**:
   - Pi 5: add `dtparam=uart0=on` and use `/dev/ttyAMA0`. (`/dev/ttyAMA10` is the separate debug connector, not the GPIO pins.)
   - Pi 3/4: add `enable_uart=1` and `dtoverlay=disable-bt` and use `/dev/ttyAMA0`.
3. **Serial over TCP / Modbus TCP:** enable **Use serial over TCP** and enter the converter's address and port. Also enable **Modbus TCP** if the converter speaks Modbus TCP (port usually `502`) rather than plain serial passthrough. No local device is needed.

App options are written to `genmon.conf` only when they are set. Leave them empty to manage these settings from the genmon web UI.

If the configured serial port does not exist, the app sets the genmon serial port to a placeholder (`/run/genmon/no-serial-port`) so genmon and its web UI still start (showing communication errors). Set the real port in the genmon web UI under **Settings** and save; genmon restarts and uses it.

## Files

- Configuration: `/data/genmon/` (kept across restarts and updates, included in HA backups)
- Logs: `/data/log/` (genmon, genserv and genloader logs are also shown in the app log)

## Differences from a normal genmon install

| Web UI action | Behavior in this app |
|---|---|
| Update | Not supported. Update the app instead. |
| Reboot | Restarts the app, not the host. |
| Shutdown | Stops the app, not the host. |
| Restart | Restarts genmon inside the app. |

Not supported: Bluetooth (Mopeka), GPIO add-ons, the LTE modem add-on.
