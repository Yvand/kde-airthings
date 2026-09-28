# Airthings device data visualizer

A KDE Plasma 6 widget (plasmoid) that displays live air quality readings and
history from your [Airthings](https://www.airthings.com/) device directly on
your desktop panel or desktop.

## Features

- Connects to your Airthings account via the official Airthings API.
- Compact panel view with an at-a-glance summary of your device's readings.
- Full (expanded) view showing every selected sensor, its current value,
  quality level (good / fair / poor) and a sparkline history chart.
- Detailed per-sensor history chart on demand.
- Supports the sensors reported by Airthings devices, including:
  - Radon (short-term average)
  - CO₂
  - VOC
  - PM1 / PM2.5
  - Humidity
  - Temperature
  - Pressure
- Configurable refresh interval, choice of which sensors to display, unit
  system (metric/imperial), and light/dark theme override for the expanded
  view.
- Available in English and French (community translations welcome).

## Screenshots

<!--
Add screenshots here before publishing to the KDE Store, e.g.:

![Compact panel view](docs/screenshots/compact.png)
![Full expanded view](docs/screenshots/full.png)
![Configuration dialog](docs/screenshots/config.png)
-->

## Requirements

- KDE Plasma 6 (`X-Plasma-API-Minimum-Version: 6.0`).
- An Airthings account with API access (client ID and client secret), and at
  least one registered Airthings device.

## Installation

### From the KDE Store (recommended)

Search for "Airthings" in Plasma's **Add Widgets** dialog (or browse
[store.kde.org](https://store.kde.org/)) and install it directly from there.

### Manual installation

1. Download the latest `.plasmoid` file from the
   [Releases](https://github.com/Yvand/kde-airthings/releases) page.
2. Install it with:
   ```bash
   kpackagetool6 --type Plasma/Applet --install /path/to/com.github.yvand.airthings-X.Y.Z.plasmoid
   ```
   or right-click your desktop/panel, choose **Add Widgets... → Get New
   Widgets... → Install Widget From Local File...**, and select the
   downloaded `.plasmoid` file.
3. Add "Airthings device data visualizer" from the widget list.

## Configuration

After adding the widget, open its settings to enter:

- Your Airthings API **client ID** and **client secret**.
- The Airthings **account** and **device** to display (auto-detected once
  credentials are valid).
- Which sensors to show, the refresh interval, unit system, and theme.

## Development

The plasmoid source lives under `package/`, following the standard Plasma
applet package layout (`package/metadata.json`, `package/contents/ui`, ...).

### Translations

```bash
translate/merge.sh   # update translate/<lang>.po from source strings
translate/build.sh    # compile .po files into package/contents/locale/
```

### Releasing

```bash
scripts/release.sh X.Y.Z
```

This bumps the version in `package/metadata.json`, commits, tags, and pushes.
Pushing the tag triggers `.github/workflows/release.yml`, which compiles
translations, packages a `.plasmoid` file, and publishes it as a GitHub
Release asset.

## License

Licensed under the [GNU General Public License v3.0 or later](LICENSE)
(GPL-3.0-or-later).
