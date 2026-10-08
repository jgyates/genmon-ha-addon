# Changelog

## 0.1.13

- Every app update now downloads the latest genmon. Before, Docker could reuse a cached download, so an app update could keep an older genmon (genmon issue #1556).
- **Rebuild** on the app page (⋮ menu) now gets the latest genmon without waiting for a new app version. Settings and logs in `/data` are kept.
- The app log shows the genmon version and commit at startup.
- Docs: genmon's **About → Update** does nothing in the app. How to get a genmon fix instead.

## 0.1.12

- Rebuild to pick up the latest genmon from `master`.
- Docs: new section on moving from an existing genmon install (Export/Import Configuration, then restart the app and set the serial port).
- Docs: how to find the boot partition with `diskpart` (always partition 1), and a GPIO header tip for a Pi 5 with an M.2 HAT+.
- Docs: SPI and I²C based genmon add-ons (CT sensor HAT, DIY fuel tank gauge) are not supported in the app. Also new FAQ entries for `raspi-config` and how genmon updates reach the app.

## 0.1.11

- Keep the outage log, service journal, kW and fuel logs and sensor history in `/data/genmon/`. Genmon wrote them to a folder inside the container, so they were lost on restart, missing from exports, and not shown after **Import Configuration**. A previous import now shows up without importing again.
- Docs: correct how to edit `config.txt` for the GPIO serial port. SSH apps can't see `/mnt/boot`; use the `docker run` command, which differs for the Pi 5 and the Pi 3/4. On Windows, a Pi 5 disk needs a drive letter assigned with `diskpart`.

## 0.1.10

- Move build settings from the deprecated `build.yaml` into the Dockerfile (removes the Supervisor "uses build.yaml which is deprecated" warning).

## 0.1.9

- Rebuild to pick up the latest genmon from `master`.
- Add a short README for the app Info tab.

## 0.1.8

- Expose port 9083 (genhalink) so the Genmon Home Assistant integration can connect.
- Add README.

## 0.1.7

- Startup page now shows progress with a countdown, switches to the web UI automatically, and shows the reason, last genmon log lines and retry countdown if genmon stops.
- Stop logging expected nginx "connection refused" errors during startup.

## 0.1.6

- Fix placeholder port: /dev is read-only in the app, so a missing port is replaced in genmon.conf with `/run/genmon/no-serial-port`.

## 0.1.5

- Create a placeholder serial device when the configured port is missing, so the genmon web UI starts and the port can be set from Settings.

## 0.1.4

- Show a help page in the sidebar panel instead of "502 Bad Gateway" while genmon is not running.

## 0.1.3

- Fix bash "pop_var_context" error when the app is stopped.

## 0.1.2

- Log a hint when only the Pi 5 debug UART (/dev/ttyAMA10) is available.
- Document GPIO UART setup for Pi 5 and Pi 3/4.

## 0.1.1

- Keep the app running and retry when genmon exits (e.g. serial port not configured yet).
- Show genmon startup errors and available serial devices in the app log.

## 0.1.0

- Initial release.
