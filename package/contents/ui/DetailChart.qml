import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "code/sensors.mjs" as Sensors

// Larger history chart of one sensor, with period selection and statistics.
ColumnLayout {
    id: detail

    property var widget
    property string sensorType
    property int hours: 24

    signal back()

    readonly property int maxPoints: 200
    readonly property int maxHours: widget.cfg.historyDays * 24
    readonly property var periods: [
        { hours: 24, label: i18n("24 hours") },
        { hours: 7 * 24, label: i18n("7 days") },
        { hours: 30 * 24, label: i18n("30 days") },
        { hours: 90 * 24, label: i18n("90 days") },
    ].filter(p => p.hours <= maxHours)
    readonly property int shownHours: Math.min(hours, maxHours)

    readonly property real toMs: { widget.historyRevision; return Date.now(); }
    readonly property real fromMs: toMs - shownHours * 3600 * 1000
    readonly property var points: sensorType ? widget.history(sensorType, fromMs, maxPoints) : []
    readonly property var stats: sensorType ? widget.historyStats(sensorType, fromMs) : null

    readonly property var reading: widget.readings.find(r => r.sensorType === sensorType) || null
    readonly property string unitText: reading ? Sensors.unitLabel(reading.unit) : ""

    function format(value) {
        return (Sensors.formatValue(sensorType, value) + " " + unitText).trim();
    }

    function formatTime(ms) {
        const date = new Date(ms);
        return shownHours <= 24 ? date.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                : date.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
    }

    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        PlasmaComponents3.ToolButton {
            icon.name: "go-previous"
            onClicked: detail.back()
            PlasmaComponents3.ToolTip.text: i18n("Back")
            PlasmaComponents3.ToolTip.visible: hovered
        }
        Kirigami.Heading {
            Layout.fillWidth: true
            level: 4
            text: detail.sensorType ? i18n(Sensors.info(detail.sensorType).name) : ""
            elide: Text.ElideRight
        }
        PlasmaComponents3.Label {
            visible: detail.reading !== null
            text: detail.reading ? detail.format(detail.reading.value) : ""
            font.bold: true
            color: detail.reading
                   ? detail.widget.qualityColor(Sensors.quality(detail.sensorType, detail.reading.value, detail.reading.unit))
                   : Kirigami.Theme.textColor
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        Repeater {
            model: detail.periods
            delegate: PlasmaComponents3.ToolButton {
                required property var modelData
                text: modelData.label
                checkable: true
                checked: modelData.hours === detail.shownHours
                onClicked: detail.hours = modelData.hours
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Y axis labels
        ColumnLayout {
            Layout.fillHeight: true
            visible: detail.points.length >= 2
            PlasmaComponents3.Label {
                text: detail.format(chart.bounds.max)
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
            }
            Item { Layout.fillHeight: true }
            PlasmaComponents3.Label {
                text: detail.format(chart.bounds.min)
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 5

            Sparkline {
                id: chart
                anchors.fill: parent
                points: detail.points
                fromMs: detail.fromMs
                toMs: detail.toMs
                maxGapMs: detail.widget.maxGapMs(detail.toMs - detail.fromMs, detail.maxPoints)
                color: Kirigami.Theme.highlightColor
                lineWidth: 2
                showGuides: true
                guideColor: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.16)
            }

            PlasmaComponents3.Label {
                anchors.centerIn: parent
                visible: detail.points.length < 2
                text: i18n("Collecting history…")
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }

    // X axis labels
    RowLayout {
        PlasmaComponents3.Label {
            text: detail.formatTime(detail.fromMs)
            color: Kirigami.Theme.disabledTextColor
            font: Kirigami.Theme.smallFont
        }
        Item { Layout.fillWidth: true }
        PlasmaComponents3.Label {
            text: i18n("Now")
            color: Kirigami.Theme.disabledTextColor
            font: Kirigami.Theme.smallFont
        }
    }

    Flow {
        id: statsRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: detail.stats !== null && detail.stats.count > 0

        Repeater {
            model: detail.stats && detail.stats.count > 0 ? [
                { label: i18n("Min"), value: detail.format(detail.stats.min) },
                { label: i18n("Average"), value: detail.format(detail.stats.avg) },
                { label: i18n("Max"), value: detail.format(detail.stats.max) },
            ] : []
            delegate: Column {
                required property var modelData
                width: Math.max(Kirigami.Units.gridUnit * 4,
                                (statsRow.width - 2 * statsRow.spacing) / 3)
                spacing: Kirigami.Units.smallSpacing / 2

                PlasmaComponents3.Label {
                    width: parent.width
                    text: modelData.label
                    color: Kirigami.Theme.disabledTextColor
                    font: Kirigami.Theme.smallFont
                }
                PlasmaComponents3.Label {
                    width: parent.width
                    text: modelData.value
                    font.bold: true
                    elide: Text.ElideRight
                }
            }
        }
    }
}
