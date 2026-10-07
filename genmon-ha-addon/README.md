<p align="center">
  <img src="https://raw.githubusercontent.com/jgyates/genmon-ha-addon/main/genmon-ha-addon/logo.png" alt="Genmon" width="160">
</p>

# Genmon – Home Assistant App

Run [genmon](https://github.com/jgyates/genmon), the open-source generator monitor for Generac, Kohler and other generator controllers, directly on your Home Assistant machine. No separate Raspberry Pi needed.

![Supports aarch64](https://img.shields.io/badge/aarch64-yes-green.svg)
![Supports amd64](https://img.shields.io/badge/amd64-yes-green.svg)

## Features

- Complete genmon (monitor, web interface and genmon add-ons) in a Home Assistant app.
- **Genmon** sidebar panel, plus direct access on port **8000**.
- Connects through a serial port. Typically a RS-232 serial port but could be RS-485 or serial over TCP depending on your generator. See [genmon Wiki] (https://github.com/jgyates/genmon/wiki) for more details.
- Port **9083** for the [Genmon Home Assistant integration](https://github.com/jgyates/genmon-ha) (sensors and buttons).
- Settings and logs survive restarts and updates, and they are included in Home Assistant backups.
- Starts without a serial port configured, so you can finish the setup in the genmon web interface.

## Getting started

1. Start the app and open **Genmon** from the sidebar.
2. Select your connection on the **Configuration** tab, or set it in the genmon web interface under **Settings**.

See the **Documentation** tab for the details, or the [full guide on GitHub](https://github.com/jgyates/genmon-ha-addon#readme).
