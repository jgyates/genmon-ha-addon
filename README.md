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
5. [Moving from an existing genmon install](#moving-from-an-existing-genmon-install)
6. [Connecting to the generator](#connecting-to-the-generator)
7. [App configuration options](#app-configuration-options)
8. [Using the web interface](#using-the-web-interface)
9. [Home Assistant integration (sensors, buttons)](#home-assistant-integration-sensors-buttons)
10. [Files, logs and backups](#files-logs-and-backups)
11. [Differences from a normal genmon install](#differences-from-a-normal-genmon-install)
12. [Updating](#updating)
13. [Troubleshooting](#troubleshooting)
14. [FAQ](#faq)
15. [How it works](#how-it-works)

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
| Connection to the generator |  Connects through a serial port. Typically a RS-232 serial port but could be RS-485 or serial over TCP depending on your generator. See [genmon Wiki](https://github.com/jgyates/genmon/wiki) for more details. |
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
- On the very first start no serial port is configured. The app then points genmon at a placeholder port (`/run/genmon/no-serial-port`), so genmon and its web interface start and show communication errors. This is expected until you configure the real connection (see [Connecting to the generator](#connecting-to-the-generator)).

## Moving from an existing genmon install

If genmon already runs on another machine (for example a Raspberry Pi), you can move everything to the app with genmon's own export and import. You don't need to copy files by hand. The export contains all settings plus the outage log, service journal, kW and fuel logs and sensor history.

1. On the **old** genmon open **About** → **Export Configuration**. This downloads `genmon_backup.tar.gz`.
   No **Export Configuration** button on an older genmon? Update genmon there first, or run `sudo ~/genmon/genmonmaint.sh -b` over SSH. It creates the same `genmon_backup.tar.gz` in the genmon folder.
2. In the **app**, open the genmon web interface → **About** → **Import Configuration** and select the file. Genmon restores it and restarts.
3. Restart the app (**Info** tab → **Restart**). This re-applies the settings the app needs (see [Settings the app always sets](#settings-the-app-always-sets)) and your app **Configuration** options, and it checks the serial port again.
4. Set the serial port for the new hardware as described in [Connecting to the generator](#connecting-to-the-generator). The import brings over the old machine's port (often `/dev/serial0`), which usually doesn't exist here. Until you set the right port, the app uses its placeholder port. Setting the port on the app's **Configuration** tab is the safest choice, because it's applied on every start.
5. Open the **Outage** and **Service Journal** pages and check that your history is there.

- Import accepts files up to 10 MB. Even years of logs normally fit, because the file is compressed.
- App versions before 0.1.11 imported the settings but didn't show the history. After updating to 0.1.11 or later, the history shows up without importing again.
- GPIO, SPI and I²C based genmon add-ons don't carry over (see [Differences from a normal genmon install](#differences-from-a-normal-genmon-install)).
- Keep the old system as it is until the app is connected to the generator, so you have a fallback.

## Connecting to the generator

Pick one method. After changing it, genmon restarts and the communication errors disappear once the controller answers.

### 1. USB-RS485 adapter (easiest, no host changes)

1. Plug the adapter into the Home Assistant machine and wire it to the generator controller.
2. In genmon open **Settings** and set **Serial port** to the adapter, usually `/dev/ttyUSB0` (some adapters show as `/dev/ttyACM0`). Save.

   Alternatively set **Serial port** on the app's **Configuration** tab and restart the app.

> Tip: `/dev/serial/by-id/...` names stay the same even if you plug in other USB devices. The app log lists all serial devices it can see.

### 2. Raspberry Pi GPIO serial port (pins 14/15)

The GPIO serial port is disabled on Home Assistant OS by default and must be enabled once in `config.txt` on the boot partition. This is the only step that cannot be done from the Home Assistant UI. The change survives Home Assistant OS updates.

| Raspberry Pi | Add to `config.txt` | Port to use |
|---|---|---|
| Pi 5 | `dtparam=uart0=on` | `/dev/ttyAMA0` |
| Pi 4 / Pi 3 | `enable_uart=1` and `dtoverlay=disable-bt` | `/dev/ttyAMA0` |

Add the lines at the very end of the file, below the last `[all]`. Use **one** of these two ways:

**Option A – on a computer (SD card / SSD removed)**

1. Shut down Home Assistant, remove the SD card / SSD and connect it to a computer.
2. Open the small boot partition (named `hassos-boot`, 32 MB on a Pi 3/4, 64 MB on a Pi 5) and edit `config.txt` as shown in the table.
3. Put the card back and boot.

> **Pi 5 disk on Windows shows no drive?** On a Pi 5, Home Assistant OS marks the boot partition as an "EFI System Partition", and Windows does not give those a drive letter. Pi 3/4 disks show up normally. To edit it anyway:
>
> 1. Open **Command Prompt as administrator** and run `diskpart`.
> 2. `list disk` → find the SD card / SSD, then `select disk N` (N = its number).
> 3. `list partition` → `select partition 1` → `assign letter=Z` → `exit`. A Home Assistant OS disk has 8 partitions, and several have similar sizes. The boot partition is always **partition 1**: the first one, 64 MB, shown as type `System`.
> 4. Open **Notepad as administrator** (Explorer may say "access denied" here, that is normal), open `Z:\config.txt`, add the line and save.
> 5. Run `diskpart` again: `select disk N` → `select partition 1` → `remove letter=Z` → `exit`. Eject the disk safely.
>
> Not sure you have the right disk or partition? Use Option B instead. It doesn't touch partitions.

**Option B – on the Pi itself, over SSH (no need to remove the disk)**

The boot partition is not visible inside SSH apps, not even with protection mode off. Samba doesn't show it either. The command below starts a short-lived helper container that can reach it.

1. Install the **Advanced SSH & Web Terminal** app and turn **Protection mode** off on its **Info** tab.
2. Open its terminal and run the command for your Pi. It adds the lines only if they are missing and then shows the end of the file:

   **Pi 5**

   ```sh
   docker run --rm -v /mnt/boot:/boot alpine sh -c 'grep -qx "dtparam=uart0=on" /boot/config.txt || echo "dtparam=uart0=on" >> /boot/config.txt; tail -n 3 /boot/config.txt'
   ```

   **Pi 4 / Pi 3**

   ```sh
   docker run --rm -v /mnt/boot:/boot alpine sh -c 'for l in enable_uart=1 dtoverlay=disable-bt; do grep -qx "$l" /boot/config.txt || echo "$l" >> /boot/config.txt; done; tail -n 4 /boot/config.txt'
   ```

   The first run downloads the small `alpine` image ("Unable to find image … locally" is expected). The output should end with the added line(s).
3. Reboot the host: `ha host reboot`.
4. Turn **Protection mode** back on. Optionally remove the helper image with `docker rmi alpine`.

**Then, for both options:** in genmon **Settings** (or the app **Configuration** tab) set **Serial port** to `/dev/ttyAMA0`. The app log lists the serial devices it can see; `/dev/ttyAMA0` should be among them.

> On a Pi 5, `/dev/ttyAMA10` is the small 3-pin debug connector next to the HDMI ports, **not** GPIO 14/15.
>
> `dtoverlay=disable-bt` turns off the on-board Bluetooth on Pi 3/4. Use a USB-RS485 adapter instead if you need Bluetooth.
>
> **Pi 5 with an M.2 HAT+ (NVMe SSD):** the HAT sits on top of the GPIO header. It is connected only through its PCIe ribbon cable, not through the GPIO pins. To reach pins 14/15 for the RS-232 board or a generator HAT, either mount the M.2 HAT+ underneath the Pi, or use a stacking header that is long enough for the pins to come up through the HAT.

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
| Genmon history | `/data/genmon/` | Outage log (`outage.txt`), service journal (`maintlog.json`), kW and fuel logs, sensor history. Genmon looks for them in `/etc/genmon/`, which the app links to this folder. |
| Genmon logs | `/data/log/` | `genmon.log`, `genserv.log`, `genloader.log` are also shown on the app **Log** tab. |

- Both locations are included in Home Assistant backups (full backups, or partial backups that include the Genmon app).
- Genmon's own **Export Configuration** and **Import Configuration** (**About** page) also work.
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
| **Update** | Does nothing in the app: genmon is part of the app image. Update or rebuild the app instead (see [Updating](#updating)). |
| **Reboot** | Restarts the app, not the Home Assistant machine. |
| **Shutdown** | Stops the app, not the Home Assistant machine. |
| **Restart** | Restarts genmon inside the app. |

Not supported inside the app: Bluetooth tank sensors (Mopeka), GPIO-based genmon add-ons (gengpio, gengpioin, gengpioledblink, gencustomgpio), add-ons that use the Pi's SPI or I²C bus (**External Current Transformer (CT) Sensors** for the PintSize.me CT HAT, **DIY Fuel Tank Gauge Sensor**), the LTE modem add-on, and Zeroconf discovery for genhalink. The app can open serial and USB devices, but not `/dev/spidev*` or `/dev/i2c-*`. Enabling SPI in `config.txt` is not enough on its own.

## Updating

Genmon is downloaded when Home Assistant builds the app image. Genmon's own **About → Update** button does nothing here. Your settings and history in `/data` (`genmon.conf`, outage log, service journal, kW/fuel logs) are kept by both options below. Don't uninstall and reinstall the app to update: uninstalling deletes `/data`.

- **App update:** when a new app version is available, Home Assistant shows an update on the app page. The image is rebuilt with the latest genmon.
- **Get a genmon fix right away (0.1.13 or later):** open the app page, click **⋮** (top right) → **Rebuild**. This downloads the latest genmon if it changed since the last build, then restarts the app. A build on a Raspberry Pi takes a few minutes.
- **Check which genmon you run:** the app **Log** tab shows a line like `genmon 2.0.2 (6d68252, 2026-10-08)` at startup. This is the genmon commit, which changes even when the version number doesn't.
- **Choosing the genmon version:** the genmon source and branch/tag are set by the `GENMON_REPO` and `GENMON_REF` defaults in the [`Dockerfile`](genmon-ha-addon/Dockerfile). After changing them, bump `version` in [`config.yaml`](genmon-ha-addon/config.yaml) so Home Assistant offers the rebuild.

## Troubleshooting

Start with the app **Log** tab – it shows the configured connection, available serial devices and genmon's own log lines.

| Symptom | Cause / fix |
|---|---|
| Sidebar shows "Genmon is starting" for a long time | Normal first start takes 30–45 s. If it stays there, check the **Log** tab. |
| Sidebar shows "Genmon is not running" | Genmon stopped. The page shows the last genmon log lines. The app retries automatically. |
| Log: `Serial port '/dev/serial0' does not exist` | No real port configured yet. Set the port as described in [Connecting to the generator](#connecting-to-the-generator). |
| Log: `Available serial devices: /dev/ttyAMA10` only (Pi 5) | GPIO UART not enabled. Add `dtparam=uart0=on` to `config.txt`, see [Raspberry Pi GPIO serial port](#2-raspberry-pi-gpio-serial-port-pins-1415). |
| Genmon runs but shows communication errors | Wrong port, wiring (A/B or TX/RX swapped), or the controller is off. See the [genmon serial troubleshooting guide](https://github.com/jgyates/genmon/wiki/3.6---Serial-Troubleshooting). |
| **Outage** / **Service Journal** pages empty after **Import Configuration** | Update the app to 0.1.11 or later. The imported history then shows up without importing again. See [Moving from an existing genmon install](#moving-from-an-existing-genmon-install). |
| A genmon fix or new setting announced on GitHub is missing | Genmon's **About → Update** does nothing in the app. Use **⋮ → Rebuild** on the app page (0.1.13 or later), or install the app update. Compare the genmon commit on the **Log** tab with [genmon's commits](https://github.com/jgyates/genmon/commits/master). See [Updating](#updating). |
| `gencthat.log`: `Error on opening SPI device` | SPI add-ons (CT sensor HAT) are not supported in the app, see [Differences](#differences-from-a-normal-genmon-install). Disable the add-on. |
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

**The genmon wiki says to run `sudo raspi-config` or `sudo reboot`, but the command is not found.**
Home Assistant OS has no `raspi-config`, and the SSH apps run in their own container, so Raspberry Pi OS commands such as `raspi-config`, `apt` or `sudo reboot` don't work there or don't affect the host. Raspberry Pi hardware options are set in `config.txt` on the boot partition instead (see [Raspberry Pi GPIO serial port](#2-raspberry-pi-gpio-serial-port-pins-1415)). In the SSH app, reboot the host with `ha host reboot`.

**Is this a separate version of genmon? Who maintains it?**
No, there is only one genmon. The app contains only the Home Assistant packaging (container setup, sidebar panel, startup page). When the image is built, it downloads genmon from the official [jgyates/genmon](https://github.com/jgyates/genmon) repository, so genmon features and fixes need no code changes in the app. A new genmon release is picked up the next time the image is built: when Home Assistant installs an app update, or when you click **Rebuild** on the app page (see [Updating](#updating)). Report genmon problems on the [genmon discussions](https://github.com/jgyates/genmon/discussions) and app problems on the [app issues](https://github.com/jgyates/genmon-ha-addon/issues).

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
