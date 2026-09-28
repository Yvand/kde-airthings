# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- The "sample recorded" time (shown in the footer, tooltip, and history)
  was computed as if the API's UTC timestamp were local time, shifting it
  by the system's UTC offset. It is now correctly converted from UTC to
  the system's local timezone.

### Changed

- The compact (panel) view now allows choosing between 1 and 4 sensors to
  display, instead of being limited to exactly 1 or 2.
- The compact view is more readable: sensors stack vertically in narrow
  (vertical) panels instead of overflowing a row, a thin divider separates
  each sensor, and hovering a sensor shows its name in a tooltip.

## [1.0.0] - 2026-09-28

### Added

- Initial release of the Airthings device data visualizer KDE Plasma 6
  widget (plasmoid).
- Connection to the Airthings account via the official Airthings API.
- Compact panel view with an at-a-glance summary of the device's readings.
- Full (expanded) view showing every selected sensor, its current value,
  quality level (good / fair / poor), and a sparkline history chart.
- Detailed per-sensor history chart on demand.
- Support for the sensors reported by Airthings devices: Radon (short-term
  average), CO₂, VOC, PM1 / PM2.5, humidity, temperature, and pressure.
- Configuration options for refresh interval, choice of displayed sensors,
  unit system (metric/imperial), and light/dark theme override for the
  expanded view.
- English and French translations.
- README screenshots for the dashboard and settings screens.

### Changed

- Widget footer now shows "sample recorded" instead of "sample" for
  clarity (#1).

[Unreleased]: https://github.com/Yvand/kde-airthings/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Yvand/kde-airthings/releases/tag/v1.0.0
