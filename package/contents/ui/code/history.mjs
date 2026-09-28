// @ts-check
// Local history of sensor readings, stored in SQLite.
// The Airthings Consumer API has no history endpoint, so the widget records every reading it fetches.
// Callers pass the database handle from QtQuick.LocalStorage.openDatabaseSync().

/** @typedef {import("./api.mjs").SensorReading} SensorReading */
/** @typedef {{ rows: { length: number, item(index: number): any } }} SqlResult */
/** @typedef {{ executeSql(sql: string, params?: any[]): SqlResult }} SqlTransaction */
/** @typedef {{ transaction(fn: (tx: SqlTransaction) => void): void, readTransaction(fn: (tx: SqlTransaction) => void): void }} Database */
/** @typedef {{ t: number, v: number }} Point  t = epoch ms, v = value */
/** @typedef {{ min: number, max: number, avg: number, count: number }} Stats */

const DAY_MS = 24 * 60 * 60 * 1000;

/** @param {Database} db */
export function init(db) {
    db.transaction((tx) => {
        // The primary key also prevents saving the same reading twice.
        tx.executeSql(
            "CREATE TABLE IF NOT EXISTS samples ("
            + "serial TEXT NOT NULL, sensor TEXT NOT NULL, ts INTEGER NOT NULL, value REAL NOT NULL, "
            + "PRIMARY KEY (serial, sensor, ts))"
        );
    });
}

/**
 * @param {Database} db
 * @param {string} serial
 * @param {number} ts  time of the reading, epoch ms
 * @param {SensorReading[]} readings
 */
export function record(db, serial, ts, readings) {
    db.transaction((tx) => {
        for (const reading of readings) {
            if (typeof reading.value === "number") {
                tx.executeSql(
                    "INSERT OR IGNORE INTO samples (serial, sensor, ts, value) VALUES (?, ?, ?, ?)",
                    [serial, reading.sensorType, Math.round(ts), reading.value]
                );
            }
        }
    });
}

/**
 * Deletes readings older than the given number of days across all devices.
 * @param {Database} db
 * @param {number} days
 */
export function prune(db, days) {
    db.transaction((tx) => {
        tx.executeSql("DELETE FROM samples WHERE ts < ?", [Date.now() - days * DAY_MS]);
    });
}

/**
 * Readings since fromMs, averaged into at most maxPoints time buckets.
 * @param {Database} db
 * @param {string} serial
 * @param {string} sensor
 * @param {number} fromMs
 * @param {number} maxPoints
 * @returns {Point[]}
 */
export function query(db, serial, sensor, fromMs, maxPoints) {
    const now = Date.now();
    const bucketMs = Math.max(1, Math.ceil((now - fromMs) / maxPoints));
    /** @type {Point[]} */
    const points = [];
    db.readTransaction((tx) => {
        const result = tx.executeSql(
            "SELECT CAST(ts / ? AS INTEGER) AS bucket, AVG(value) AS v FROM samples "
            + "WHERE serial = ? AND sensor = ? AND ts >= ? GROUP BY bucket ORDER BY bucket",
            [bucketMs, serial, sensor, fromMs]
        );
        for (let i = 0; i < result.rows.length; i++) {
            const row = result.rows.item(i);
            points.push({ t: Math.min(now, (row.bucket + 0.5) * bucketMs), v: row.v });
        }
    });
    return points;
}

/**
 * Min, max and average of the raw readings since fromMs.
 * @param {Database} db
 * @param {string} serial
 * @param {string} sensor
 * @param {number} fromMs
 * @returns {Stats}
 */
export function stats(db, serial, sensor, fromMs) {
    /** @type {Stats} */
    let result = { min: 0, max: 0, avg: 0, count: 0 };
    db.readTransaction((tx) => {
        const row = tx.executeSql(
            "SELECT MIN(value) AS min, MAX(value) AS max, AVG(value) AS avg, COUNT(*) AS count "
            + "FROM samples WHERE serial = ? AND sensor = ? AND ts >= ?",
            [serial, sensor, fromMs]
        ).rows.item(0);
        if (row.count > 0) {
            result = { min: row.min, max: row.max, avg: row.avg, count: row.count };
        }
    });
    return result;
}

/**
 * @param {Database} db
 * @param {string} serial
 * @returns {number}
 */
export function count(db, serial) {
    let total = 0;
    db.readTransaction((tx) => {
        total = tx.executeSql("SELECT COUNT(*) AS n FROM samples WHERE serial = ?", [serial]).rows.item(0).n;
    });
    return total;
}

/**
 * @param {Database} db
 * @param {string} serial
 */
export function clear(db, serial) {
    db.transaction((tx) => {
        tx.executeSql("DELETE FROM samples WHERE serial = ?", [serial]);
    });
}
