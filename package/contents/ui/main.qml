import QtQuick
import QtQuick.LocalStorage
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "code/api.mjs" as Api
import "code/history.mjs" as History

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property bool configured: cfg.clientId !== "" && cfg.clientSecret !== ""
                                       && cfg.accountId !== "" && cfg.deviceSerial !== ""

    // ---- Latest data from the API ----
    property var readings: []           // [{ sensorType, value, unit }]
    property real lastFetchedMs: 0      // time the API request succeeded
    property real lastUpdatedMs: 0
    property int battery: -1            // -1 = unknown
    property string errorMessage: ""
    property bool loading: false
    property int historyRevision: 0     // bumped after each save so charts reload

    // An empty selection means "show every sensor".
    readonly property var visibleReadings: {
        const wanted = cfg.visibleSensors;
        return wanted.length === 0 ? readings : readings.filter(r => wanted.indexOf(r.sensorType) !== -1);
    }
    readonly property int sparklineHours: Math.min(cfg.sparklineHours, cfg.historyDays * 24)

    // ---- Theme: follow Plasma, or force light/dark in the full view ----
    readonly property bool forcedTheme: cfg.themeMode === "light" || cfg.themeMode === "dark"
    readonly property bool dark: cfg.themeMode === "dark"
    readonly property color textColor: !forcedTheme ? Kirigami.Theme.textColor : dark ? "#fcfcfc" : "#232629"
    readonly property color subtleTextColor: !forcedTheme ? Kirigami.Theme.disabledTextColor : dark ? "#a1a9b1" : "#6e7780"
    readonly property color backgroundColor: !forcedTheme ? Kirigami.Theme.backgroundColor : dark ? "#202326" : "#f7f7f7"
    readonly property color accentColor: !forcedTheme ? Kirigami.Theme.highlightColor : "#3daee9"

    function qualityColor(quality) {
        switch (quality) {
        case "good": return "#27ae60";
        case "fair": return "#f67400";
        case "poor": return "#da4453";
        default: return accentColor;
        }
    }

    // ---- API and history storage ----
    property var client: new Api.Client(cfg.clientId, cfg.clientSecret)
    readonly property string credentialsKey: cfg.clientId + "\n" + cfg.clientSecret
    readonly property var db: LocalStorage.openDatabaseSync("AirthingsWidget", "", "Airthings widget history", 10 * 1024 * 1024)

    function history(sensorType, fromMs, maxPoints) {
        return History.query(db, cfg.deviceSerial, sensorType, fromMs, maxPoints);
    }

    function historyStats(sensorType, fromMs) {
        return History.stats(db, cfg.deviceSerial, sensorType, fromMs);
    }

    // Points further apart than this are not connected in charts (the widget was not running).
    function maxGapMs(rangeMs, maxPoints) {
        return Math.max(3 * cfg.refreshMinutes * 60 * 1000, 2 * rangeMs / maxPoints);
    }

    function errorText(error) {
        if (!error || typeof error.status !== "number") {
            return String(error);
        }
        if (error.auth) {
            return i18n("Invalid client credentials");
        }
        if (error.status === 0) {
            return i18n("Cannot reach the Airthings API. Check your network connection.");
        }
        if (error.status === 429) {
            return i18n("Rate limit reached (120 requests per hour). Increase the refresh interval.");
        }
        return i18n("Airthings API error %1: %2", error.status, i18n(error.message));
    }

    function refresh() {
        const serial = cfg.deviceSerial;
        loading = true;
        client.latest(cfg.accountId, serial, cfg.unitSystem).then(result => {
            loading = false;
            if (serial !== cfg.deviceSerial) {
                return; // device changed while the request was running
            }
            lastFetchedMs = Date.now();
            if (!result) {
                errorMessage = i18n("No readings available for this device yet");
                return;
            }
            const recordedMs = Api.parseUtcTimestamp(result.recorded) || Date.now();
            readings = result.sensors;
            battery = typeof result.batteryPercentage === "number" ? result.batteryPercentage : -1;
            lastUpdatedMs = recordedMs;
            errorMessage = "";

            History.record(db, serial, recordedMs, result.sensors);
            History.prune(db, cfg.historyDays);
            historyRevision++;
        }, error => {
            loading = false;
            errorMessage = errorText(error);
        });
    }

    // Start over with fresh data.
    function restart() {
        readings = [];
        errorMessage = "";
        lastFetchedMs = 0;
        lastUpdatedMs = 0;
        if (configured) {
            refreshTimer.restart();
        } else {
            refreshTimer.stop();
        }
    }

    // Changing any of these settings starts over.
    readonly property string dataSource: [cfg.clientId, cfg.clientSecret, cfg.accountId, cfg.deviceSerial, cfg.unitSystem].join("\n")
    onCredentialsKeyChanged: client = new Api.Client(cfg.clientId, cfg.clientSecret)
    onDataSourceChanged: restart()

    Component.onCompleted: {
        History.init(db);
        restart();
    }

    Timer {
        id: refreshTimer
        interval: root.cfg.refreshMinutes * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Plasmoid.backgroundHints: forcedTheme ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh now")
            icon.name: "view-refresh"
            enabled: root.configured
            onTriggered: root.refresh()
        }
    ]

    toolTipMainText: cfg.deviceName || i18n("Airthings")
    toolTipSubText: errorMessage !== "" ? errorMessage
                                        : lastFetchedMs > 0
                                            ? i18n("Fetched %1 · sample recorded %2",
                                                         new Date(lastFetchedMs).toLocaleTimeString(Qt.locale(), Locale.ShortFormat),
                                                         new Date(lastUpdatedMs).toLocaleTimeString(Qt.locale(), Locale.ShortFormat))
                    : ""

    compactRepresentation: CompactRepresentation {
        widget: root
    }

    fullRepresentation: FullRepresentation {
        widget: root
    }
}
