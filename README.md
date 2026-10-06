<p align="center">
  <img src="genmon-ha-addon/logo.png" alt="Genmon" width="160">
</p>

# Genmon – Home Assistant App

Run [genmon](https://github.com/jgyates/genmon), the open-source generator monitor for Generac, Kohler and other generator controllers, directly on your Home Assistant machine. No separate Raspberry Pi needed.

![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)

---

## Contents

1. [What this app does](#what-this-app-does)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [First start](#first-start)
5. [Connecting to the generator](#connecting-to-the-generator)
6. [App configuration options](#app-configuration-options)
7. [Using the web interface](#using-the-web-interface)
8. [Home Assistant integration (sensors, buttons)](#home-assistant-integration-sensors-buttons)
9. [Files, logs and backups](#files-logs-and-backups)
10. [Differences from a normal genmon install](#differences-from-a-normal-genmon-install)
11. [Updating](#updating)
12. [Troubleshooting](#troubleshooting)
13. [FAQ](#faq)
14. [How it works](#how-it-works)

---

## What this app does

- Runs the complete genmon software (monitor, web interface and genmon add-ons) inside a Home Assistant app container.
- Adds a **Genmon** entry to the Home Assistant sidebar that opens the genmon web interface.
- Also exposes the genmon web interface on port **8000** for direct access from any browser.
- Keeps all genmon settings and logs in the app's persistent storage, so they survive restarts, updates and are included in Home Assistant backups.
- Starts genmon automatically when Home Assistant boots and restarts it if it stops.
- Works without a serial port configured: genmon starts with a placeholder port so you can finish the setup from the genmon web interface.

## Requirements

| Item | Details |
|---|---|
| Home Assistant | Home Assistant OS or Supervised (apps are not available on Container/Core installs) |
| Hardware | 64-bit ARM (Raspberry Pi 3/4/5, `aarch64`) or 64-bit x86 (`amd64`, e.g. mini PC, NUC, VM) |
| Connection to the generator | One of: USB-RS485 adapter, Raspberry Pi GPIO serial port (UART), or a serial-to-network converter |
| Disk space | About 1 GB for the image (it is built on your machine during installation) |

## Installation

### Option A – Add the repository (recommended)

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fjgyates%2Fgenmon-ha-addon)

Or manually:

1. In Home Assistant open **Settings → Apps → App store** (older versions: **Settings → Add-ons → Add-on store**).
2. Click the **⋮** menu (top right) → **Repositories**.
3. Add `https://github.com/jgyates/genmon-ha-addon` and click **Add**, then **Close**.
4. Refresh the page. **Genmon** appears in the store.
5. Open **Genmon** and click **Install**.

> The first installation builds the image on your machine. On a Raspberry Pi this can take 10–20 minutes. Later starts take about 30 seconds.

### Option B – Local install (no GitHub needed)

1. Install the **Samba share** or **Advanced SSH & Web Terminal** app if you don't have one.
2. Copy the complete `genmon-ha-addon` folder into the `addons` share of your Home Assistant machine (for example `\\homeassistant\addons\genmon-ha-addon`).
3. Open **Settings → Apps → App store**, click **⋮ → Check for updates**.
4. **Genmon** appears under **Local apps**. Open it and click **Install**.

### After installation

1. On the **Info** tab enable **Start on boot**, **Watchdog** and **Show in sidebar**.
2. Click **Start**.
3. Open **Genmon** in the sidebar.

## First start

- While genmon starts (about 30–45 seconds) the sidebar panel shows a status page with a progress bar and countdown. It switches to the genmon web interface automatically.
- If genmon cannot start, the same page shows the reason, the last lines of the genmon log and when the next automatic retry happens.
- On the very first start no serial port is configured. The app then points genmon at a placeholder port (`/run/genmon/no-serial-port`), so genmon and its web interface start and show communication errors. This is expected until you configure the real connection (next section).

## Connecting to the generator

Pick one method. After changing it, genmon restarts and the communication errors disappear once the controller answers.

### 1. USB-RS485 adapter (easiest, no host changes)

1. Plug the adapter into the Home Assistant machine and wire it to the generator controller.
2. In genmon open **Settings** and set **Serial port** to the adapter, usually `/dev/ttyUSB0` (some adapters show as `/dev/ttyACM0`). Save.

   Alternatively set **Serial port** on the app's **Configuration** tab and restart the app.

> Tip: `/dev/serial/by-id/...` names stay the same even if you plug in other USB devices. The app log lists all serial devices it can see.

### 2. Raspberry Pi GPIO serial port (pins 14/15)

The GPIO serial port is disabled on Home Assistant OS by default and must be enabled once in the boot configuration. This is the only step that cannot be done from the Home Assistant UI.

1. Shut down Home Assistant, remove the SD card / SSD and connect it to a computer.
2. Open the small boot partition (named `hassos-boot`) and edit `config.txt`. Add at the end:

   | Raspberry Pi | Add to `config.txt` | Port to use |
   |---|---|---|
   | Pi 5 | `dtparam=uart0=on` | `/dev/ttyAMA0` |
   | Pi 4 / Pi 3 | `enable_uart=1` and `dtoverlay=disable-bt` | `/dev/ttyAMA0` |

3. Put the card back and boot.
4. In genmon **Settings** (or the app **Configuration** tab) set **Serial port** to `/dev/ttyAMA0`.

> On a Pi 5, `/dev/ttyAMA10` is the small 3-pin debug connector next to the HDMI ports, **not** GPIO 14/15.
>
> `dtoverlay=disable-bt` turns off the on-board Bluetooth on Pi 3/4. Use a USB-RS485 adapter instead if you need Bluetooth.

### 3. Serial-to-network converter (serial over TCP / Modbus TCP)

1. Connect a serial-to-Ethernet/Wi-Fi converter to the generator controller and set it to 9600 baud, 8N1.
2. In genmon **Settings** (or the app **Configuration** tab):
   - Enable **Use serial over TCP**.
   - Enter the converter's IP address and port (typically `8899`).
   - Enable **Modbus TCP** only if the converter speaks Modbus TCP (then the port is usually `502`).

## App configuration options

All options are optional. When an option is left empty, the value in genmon's own settings is used, so you can manage everything from the genmon web interface. When an option is set, it is written to genmon's settings on every app start and overrides the genmon web interface.

| Option | Description |
|---|---|
| **Serial port** | Serial device connected to the controller, e.g. `/dev/ttyUSB0` or `/dev/ttyAMA0`. |
| **Use serial over TCP** | Use a serial-to-network converter instead of a local serial port. |
| **Serial TCP address** | IP address of the converter. |
| **Serial TCP port** | TCP port of the converter (`8899` typical, `502` for Modbus TCP). |
| **Modbus TCP** | Use the Modbus TCP protocol instead of plain serial passthrough over TCP. |

### Network ports

| Port | Purpose | Notes |
|---|---|---|
| 8000/tcp | Genmon web interface (direct access) | Set to empty on the **Network** section to disable direct access and use only the sidebar. |
| 9083/tcp | genhalink API | Used by the Genmon Home Assistant integration. Disable if you don't use it. |

## Using the web interface

| Access | URL | Login |
|---|---|---|
| Sidebar panel | Click **Genmon** in the Home Assistant sidebar | Home Assistant login |
| Direct | `http://<home-assistant-ip>:8000/` | Genmon login (if configured) |

- The sidebar panel only works over plain HTTP, so the app turns genmon's **HTTPS** option off on every start. If you need HTTPS, use Home Assistant's own HTTPS (e.g. Nabu Casa or a reverse proxy) and the sidebar panel.
- Anyone who can reach port 8000 can use the direct web interface. Either set a genmon username and password (**Settings → Security**) or disable port 8000 on the app's **Configuration** tab.
- Passkeys (WebAuthn) only work on the direct port.

## Home Assistant integration (sensors, buttons)

This app runs genmon itself. To get generator sensors, binary sensors, buttons and switches in Home Assistant, use one of genmon's own Home Assistant links:

### Native integration (genhalink) – recommended

1. In genmon open **Settings** and enable **Home Assistant Integration (Native)**. Copy the generated **API key**. Save.
2. Install the **Genmon Generator Monitor** integration through **HACS** (see [`custom_components/genmon`](https://github.com/jgyates/genmon-ha)).
3. In Home Assistant go to **Settings → Devices & Services → Add Integration → Genmon** and enter:
   - **Host:** the IP address of your Home Assistant machine
   - **Port:** `9083`
   - **API key:** the key from step 1

> Automatic discovery (Zeroconf) does not work from inside the app, so add the integration manually as shown above.

### MQTT

Enable the genmon **MQTT** add-on in genmon and point it at your MQTT broker (for example the Mosquitto broker app, host `core-mosquitto`, port `1883`).

## Files, logs and backups

| What | Location inside the app | Notes |
|---|---|---|
| Genmon settings | `/data/genmon/` | All `*.conf` files. Missing files are added from the defaults on every start; existing files are never overwritten. |
| Genmon logs | `/data/log/` | `genmon.log`, `genserv.log`, `genloader.log` are also shown on the app **Log** tab. |

- Both locations are included in Home Assistant backups (full backups, or partial backups that include the Genmon app).
- Genmon's own **Backup** and **Restore** in the web interface also work.
- Uninstalling the app deletes these files. Make a backup first if you want to keep your settings.

### Settings the app always sets

| genmon setting | Value | Why |
|---|---|---|
| `loglocation` | `/data/log/` | Keeps logs persistent |
| `http_port` | `8000` | The sidebar panel and port mapping depend on it |
| `usehttps` | `False` | The sidebar panel requires plain HTTP |

## Differences from a normal genmon install

| Genmon web interface action | Behavior in this app |
|---|---|
| **Update** | Not supported – update the app instead (see below). |
| **Reboot** | Restarts the app, not the Home Assistant machine. |
| **Shutdown** | Stops the app, not the Home Assistant machine. |
| **Restart** | Restarts genmon inside the app. |

Not supported inside the app: Bluetooth tank sensors (Mopeka), GPIO-based genmon add-ons (gengpio, gengpioin, gengpioledblink, gencustomgpio), the LTE modem add-on, and Zeroconf discovery for genhalink.

## Updating

- **App update:** when a new app version is available, Home Assistant shows an update on the app page. The image is rebuilt with the genmon version defined by the app. Your settings in `/data` are kept.
- **Choosing the genmon version:** the genmon source and branch/tag are set by the `GENMON_REPO` and `GENMON_REF` defaults in the [`Dockerfile`](genmon-ha-addon/Dockerfile). After changing them, bump `version` in [`config.yaml`](genmon-ha-addon/config.yaml) so Home Assistant offers the rebuild.

## Troubleshooting

Start with the app **Log** tab – it shows the configured connection, available serial devices and genmon's own log lines.

| Symptom | Cause / fix |
|---|---|
| Sidebar shows "Genmon is starting" for a long time | Normal first start takes 30–45 s. If it stays there, check the **Log** tab. |
| Sidebar shows "Genmon is not running" | Genmon stopped. The page shows the last genmon log lines. The app retries automatically. |
| Log: `Serial port '/dev/serial0' does not exist` | No real port configured yet. Set the port as described in [Connecting to the generator](#connecting-to-the-generator). |
| Log: `Available serial devices: /dev/ttyAMA10` only (Pi 5) | GPIO UART not enabled. Add `dtparam=uart0=on` to `config.txt`. |
| Genmon runs but shows communication errors | Wrong port, wiring (A/B or TX/RX swapped), or the controller is off. See the [genmon serial troubleshooting guide](https://github.com/jgyates/genmon/wiki/3.6---Serial-Troubleshooting). |
| `genloader.log` shows `PID still exists but it's a zombie` | Harmless message from genmon's loader when a module exits; it also appears on normal installs. |
| Direct port 8000 doesn't load | Check the port is not disabled under **Network** on the **Configuration** tab, and that genmon is running. |
| Integration cannot connect | Enable genhalink in genmon, keep port 9083 enabled, use the Home Assistant machine's IP address. |

When asking for help on the [genmon discussions](https://github.com/jgyates/genmon/discussions), include the app log, your hardware (Pi model or PC), the connection method and the generator/controller model.

## FAQ

**Can I install this app through HACS?**
No. HACS installs integrations, dashboards cards and themes – it cannot install Home Assistant apps. Apps are installed from the app store after adding this repository (see [Installation](#installation)). The separate **Genmon Generator Monitor** integration *is* installed through HACS.

**Does this work with Home Assistant Container or Core?**
No. Apps require Home Assistant OS or Supervised. On other installs run genmon directly on Linux or in Docker.

**Can I still run genmon on a separate Raspberry Pi?**
Yes. This app is optional. The Home Assistant integrations work the same with either setup.

**Will the app change anything on my Home Assistant host?**
No. The only host change you may make yourself is enabling the Raspberry Pi GPIO serial port in `config.txt`.

**Where is genmon's `genmon.conf`?**
In `/data/genmon/` inside the app. Edit settings through the genmon web interface; manual edits are not needed.

## How it works

```
Browser ──► Home Assistant sidebar (ingress) ──► nginx :8099 ──► genserv :8000 (Flask web UI)
Browser ──────────────────────────────────────── direct :8000 ──┘
                                                                  │ TCP 9082
                                                                  ▼
                                    genmon.py ──► serial port / TCP converter ──► generator controller
```

- **run.sh** prepares the settings in `/data/genmon`, starts nginx and genmon (via genmon's `genloader.py`), keeps genmon running and writes the status shown on the startup page.
- **nginx** serves the sidebar panel: it rewrites genmon's few absolute links to work under Home Assistant's ingress path, allows the page inside the Home Assistant frame and shows the startup/status page while genmon is not reachable.
- Small helper commands replace `sudo`, `reboot` and `shutdown` inside the container so genmon's Restart/Reboot/Shutdown buttons act on the app instead of the host.
- The image is built from the genmon source at build time (`git clone`), with all Python libraries pre-installed so nothing is downloaded at start.

---

Genmon is developed by [jgyates](https://github.com/jgyates/genmon) and contributors and is released under the GPL-2.0 license.
