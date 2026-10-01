// @ts-check
// Display metadata and air-quality classification for Airthings sensor types.

/** @typedef {"good" | "fair" | "poor" | "none"} Quality */
/** @typedef {{ good: [number, number], fair: [number, number] }} Levels  inclusive [min, max] ranges */
/** @typedef {{ name: string, decimals: number, levelUnits?: string[] }} SensorInfo */
/** @typedef {Record<string, Record<string, Levels>>} ConfiguredLevels */
/** @typedef {{ type: string, unit: string, key: string, decimals: number }} LevelDefinition */

// Marks names for extraction into the translation template; QML translates them with i18n().
/** @param {string} text */
const I18N_NOOP = text => text;

/** @type {Record<string, SensorInfo>} */
const SENSORS = {
    radonShortTermAvg: {
        name: I18N_NOOP("Radon"),
        decimals: 0,
        levelUnits: ["bq", "pci"],
    },
    co2: { name: I18N_NOOP("CO₂"), decimals: 0, levelUnits: ["ppm"] },
    voc: { name: I18N_NOOP("VOC"), decimals: 0, levelUnits: ["ppb"] },
    pm1: { name: I18N_NOOP("PM1"), decimals: 0, levelUnits: ["mgpc"] },
    pm25: { name: I18N_NOOP("PM2.5"), decimals: 0, levelUnits: ["mgpc"] },
    humidity: { name: I18N_NOOP("Humidity"), decimals: 0, levelUnits: ["pct"] },
    temp: {
        name: I18N_NOOP("Temperature"),
        decimals: 1,
        levelUnits: ["c", "f"],
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

/** Config keys and UI precision for every classified sensor/unit pair. */
/** @type {LevelDefinition[]} */
export const LEVEL_DEFINITIONS = [
    { type: "radonShortTermAvg", unit: "bq", key: "radonBq", decimals: 0 },
    { type: "radonShortTermAvg", unit: "pci", key: "radonPci", decimals: 1 },
    { type: "co2", unit: "ppm", key: "co2Ppm", decimals: 0 },
    { type: "voc", unit: "ppb", key: "vocPpb", decimals: 0 },
    { type: "pm1", unit: "mgpc", key: "pm1Mgpc", decimals: 0 },
    { type: "pm25", unit: "mgpc", key: "pm25Mgpc", decimals: 0 },
    { type: "humidity", unit: "pct", key: "humidityPct", decimals: 0 },
    { type: "temp", unit: "c", key: "tempC", decimals: 1 },
    { type: "temp", unit: "f", key: "tempF", decimals: 1 },
];

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
 * Builds the quality-level object from Plasmoid.configuration.
 * @param {Record<string, any>} config
 * @returns {ConfiguredLevels}
 */
export function configuredLevels(config) {
    /** @type {ConfiguredLevels} */
    const result = {};
    for (const definition of LEVEL_DEFINITIONS) {
        const prefix = definition.key;
        const goodMin = Number(config[`${prefix}GoodMin`]);
        const goodMax = Number(config[`${prefix}GoodMax`]);
        const fairMin = Number(config[`${prefix}FairMin`]);
        const fairMax = Number(config[`${prefix}FairMax`]);
        if (![fairMin, goodMin, goodMax, fairMax].every(Number.isFinite)
                || fairMin > goodMin || goodMin > goodMax || goodMax > fairMax) {
            console.warn(`Ignoring invalid sensor level configuration for ${definition.type} (${definition.unit})`);
            continue;
        }
        if (!result[definition.type]) {
            result[definition.type] = {};
        }
        result[definition.type][definition.unit] = { good: [goodMin, goodMax], fair: [fairMin, fairMax] };
    }
    return result;
}

/**
 * @param {string} type
 * @param {number} value
 * @param {string} unit
 * @param {ConfiguredLevels} configured
 * @returns {Quality}
 */
export function quality(type, value, unit, configured) {
    const levels = configured[type];
    const range = levels && levels[unit];
    if (!range || typeof value !== "number" || !Number.isFinite(value)) {
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
