import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

import "code/sensors.mjs" as Sensors

// Shown on the desktop and in the panel popup: sensor tiles, or the detail chart of one sensor.
Item {
    id: full

    property var widget
    property string detailSensor: ""    // sensor shown in the detail chart; "" shows the tiles

    readonly property var readings: widget.visibleReadings
    readonly property string layoutMode: widget.cfg.layoutMode   // grid, list or row
    readonly property real spacing: Kirigami.Units.smallSpacing * 2
    readonly property real margin: widget.forcedTheme ? Kirigami.Units.largeSpacing : 0
    readonly property real tileMinWidth: Kirigami.Units.gridUnit * 7
    readonly property real tileHeight: Kirigami.Units.gridUnit * (widget.cfg.showSparklines ? 5.5 : 3.5)
    readonly property int sparklinePoints: 60

    // Initial size; the widget can be resized on the desktop.
    readonly property int preferredColumns: layoutMode === "list" ? 1
                                          : layoutMode === "row" ? Math.max(1, readings.length)
                                          : Math.min(3, Math.max(1, readings.length))
    readonly property int preferredRows: Math.max(1, Math.ceil(readings.length / preferredColumns))
    Layout.preferredWidth: preferredColumns * tileMinWidth + (preferredColumns - 1) * spacing + 2 * margin
    Layout.preferredHeight: detailSensor !== "" ? Kirigami.Units.gridUnit * 16 + 2 * margin
                            : preferredRows * tileHeight + (preferredRows - 1) * spacing + Kirigami.Units.gridUnit * 5 + 2 * margin
    Layout.minimumWidth: Kirigami.Units.gridUnit * 10
    Layout.minimumHeight: Kirigami.Units.gridUnit * (detailSensor !== "" ? 13 : 8)

    // Light/dark override: child Kirigami and Plasma controls use these colours.
    Kirigami.Theme.inherit: !widget.forcedTheme
    Kirigami.Theme.textColor: widget.textColor
    Kirigami.Theme.disabledTextColor: widget.subtleTextColor
    Kirigami.Theme.backgroundColor: widget.backgroundColor
    Kirigami.Theme.highlightColor: widget.accentColor

    Rectangle {
        anchors.fill: parent
        visible: full.widget.forcedTheme
        color: full.widget.backgroundColor
        radius: Kirigami.Units.cornerRadius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: full.margin
        spacing: full.spacing
        visible: full.readings.length > 0

        RowLayout {
            Layout.fillWidth: true
            spacing: full.spacing
            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: full.widget.cfg.deviceName || i18n("Airthings")
                elide: Text.ElideRight
            }
            PlasmaComponents3.BusyIndicator {
                visible: full.widget.loading
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: full.detailSensor === "" ? 0 : 1

            PlasmaComponents3.ScrollView {
                id: scroll
                contentWidth: grid.width
                contentHeight: grid.implicitHeight

                GridLayout {
                    id: grid
                    // Only the row layout scrolls horizontally.
                    width: full.layoutMode === "row" ? Math.max(scroll.availableWidth, implicitWidth) : scroll.availableWidth
                    rowSpacing: full.spacing
                    columnSpacing: full.spacing
                    columns: full.layoutMode === "list" ? 1
                           : full.layoutMode === "row" ? Math.max(1, full.readings.length)
                           : Math.max(1, Math.floor((scroll.availableWidth + full.spacing) / (full.tileMinWidth + full.spacing)))

                    Repeater {
                        model: full.readings
                        delegate: SensorTile {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.minimumWidth: full.layoutMode === "row" ? full.tileMinWidth
                                                 : Math.min(full.tileMinWidth, scroll.availableWidth)
                            Layout.preferredWidth: full.tileMinWidth
                            Layout.preferredHeight: full.tileHeight

                            name: i18n(Sensors.info(modelData.sensorType).name)
                            valueText: Sensors.formatValue(modelData.sensorType, modelData.value)
                            unitText: Sensors.unitLabel(modelData.unit)
                            readonly property string quality: Sensors.quality(modelData.sensorType, modelData.value, modelData.unit)
                            qualityColor: full.widget.qualityColor(quality)
                            qualityLabel: quality === "good" ? i18n("Good")
                                        : quality === "fair" ? i18n("Fair")
                                        : quality === "poor" ? i18n("Poor") : ""

                            showSparkline: full.widget.cfg.showSparklines
                            toMs: { full.widget.historyRevision; return Date.now(); }
                            fromMs: toMs - full.widget.sparklineHours * 3600 * 1000
                            points: showSparkline ? full.widget.history(modelData.sensorType, fromMs, full.sparklinePoints) : []
                            maxGapMs: full.widget.maxGapMs(toMs - fromMs, full.sparklinePoints)

                            onClicked: full.detailSensor = modelData.sensorType
                        }
                    }
                }
            }

            DetailChart {
                widget: full.widget
                sensorType: full.detailSensor
                onBack: full.detailSensor = ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: metadata.visible || errorRow.visible
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Separator { Layout.fillWidth: true }

            RowLayout {
                id: metadata
                Layout.fillWidth: true
                spacing: full.spacing
                visible: fetchedLabel.visible || batteryLabel.visible

                PlasmaComponents3.Label {
                    id: fetchedLabel
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: full.widget.cfg.showLastUpdated && full.widget.lastFetchedMs > 0
                    text: {
                        const fetched = i18n("Fetched %1", new Date(full.widget.lastFetchedMs).toLocaleTimeString(Qt.locale(), Locale.ShortFormat));
                        return full.widget.lastUpdatedMs > 0
                               ? fetched + " · " + i18n("sample %1", new Date(full.widget.lastUpdatedMs).toLocaleTimeString(Qt.locale(), Locale.ShortFormat))
                               : fetched;
                    }
                    color: Kirigami.Theme.disabledTextColor
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                }

                PlasmaComponents3.Label {
                    id: batteryLabel
                    visible: full.widget.cfg.showBattery && full.widget.battery >= 0
                    // xgettext:no-javascript-format
                    text: i18n("Battery %1%", full.widget.battery)
                    color: Kirigami.Theme.disabledTextColor
                    font: Kirigami.Theme.smallFont
                }
            }

            RowLayout {
                id: errorRow
                Layout.fillWidth: true
                visible: full.widget.errorMessage !== ""
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "dialog-warning"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: implicitWidth
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: full.widget.errorMessage   // readings shown are from an earlier refresh
                    color: Kirigami.Theme.textColor
                    font: Kirigami.Theme.smallFont
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 2
        visible: full.readings.length === 0

        iconName: !full.widget.configured ? "configure"
                : full.widget.errorMessage !== "" ? "dialog-warning"
                : "view-refresh"
        text: !full.widget.configured ? i18n("Not configured")
            : full.widget.errorMessage !== "" ? i18n("Cannot load readings")
            : full.widget.loading ? i18n("Loading…")
            : i18n("No readings to show")
        explanation: !full.widget.configured ? i18n("Enter your Airthings client credentials and choose a device.")
                   : full.widget.errorMessage
        helpfulAction: full.widget.configured ? null : configureAction
    }

    QQC2.Action {
        id: configureAction
        text: i18n("Configure…")
        icon.name: "configure"
        onTriggered: Plasmoid.internalAction("configure").trigger()
    }
}
