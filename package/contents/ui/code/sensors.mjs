// @ts-check
// Display metadata for Airthings sensor types: names, units, decimals and air quality levels.

/** @typedef {"good" | "fair" | "poor" | "none"} Quality */
/** @typedef {{ good: [number, number], fair: [number, number] }} Levels  inclusive [min, max] ranges */
/** @typedef {{ name: string, decimals: number, levels?: Record<string, Levels> }} SensorInfo  levels keyed by API unit */

// Marks names for extraction into the translation template; QML translates them with i18n().
/** @param {string} text */
const I18N_NOOP = text => text;

/** @type {Record<string, SensorInfo>} */
const SENSORS = {
    radonShortTermAvg: {
        name: I18N_NOOP("Radon"),
        decimals: 0,
        levels: {
            bq: { good: [0, 100], fair: [0, 150] },
            pci: { good: [0, 2.7], fair: [0, 4] },
        },
    },
    co2: { name: I18N_NOOP("CO₂"), decimals: 0, levels: { ppm: { good: [0, 800], fair: [0, 1000] } } },
    voc: { name: I18N_NOOP("VOC"), decimals: 0, levels: { ppb: { good: [0, 250], fair: [0, 2000] } } },
    pm1: { name: I18N_NOOP("PM1"), decimals: 0, levels: { mgpc: { good: [0, 10], fair: [0, 25] } } },
    pm25: { name: I18N_NOOP("PM2.5"), decimals: 0, levels: { mgpc: { good: [0, 10], fair: [0, 25] } } },
    humidity: { name: I18N_NOOP("Humidity"), decimals: 0, levels: { pct: { good: [30, 60], fair: [25, 70] } } },
    temp: {
        name: I18N_NOOP("Temperature"),
        decimals: 1,
        levels: {
            c: { good: [18, 25], fair: [16, 27] },
            f: { good: [64, 77], fair: [61, 81] },
        },
    },
    pressure: { name: I18N_NOOP("Pressure"), decimals: 0 },
    light: { name: I18N_NOOP("Light"), decimals: 0 },
};

/** @type {Record<string, string>} */
const UNIT_LABELS = {
    bq: "Bq/m³",
    pci: "pCi/L",
    c: "°C",
    f: "°F",
    pct: "%",
    mbar: "hPa",
    inhg: "inHg",
    ppm: "ppm",
    ppb: "ppb",
    mgpc: "µg/m³",
    lux: "lx",
};

/** Sensor types the widget knows about, in display order. */
export const SENSOR_TYPES = Object.keys(SENSORS);

/**
 * @param {string} type
 * @returns {SensorInfo}
 */
export function info(type) {
    return SENSORS[type] || { name: type, decimals: 1 };
}

/** @param {string} unit */
export function unitLabel(unit) {
    return UNIT_LABELS[unit] || unit || "";
}

/**
 * @param {string} type
 * @param {number} value
 */
export function formatValue(type, value) {
    return typeof value === "number" ? value.toFixed(info(type).decimals) : "–";
}

/**
 * @param {string} type
 * @param {number} value
 * @param {string} unit
 * @returns {Quality}
 */
export function quality(type, value, unit) {
    const levels = info(type).levels;
    const range = levels && levels[unit];
    if (!range || typeof value !== "number") {
        return "none";
    }
    if (value >= range.good[0] && value <= range.good[1]) {
        return "good";
    }
    if (value >= range.fair[0] && value <= range.fair[1]) {
        return "fair";
    }
    return "poor";
}
