# Changelog

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
