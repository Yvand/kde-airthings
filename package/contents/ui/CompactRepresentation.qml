import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "code/sensors.mjs" as Sensors

// Shown in panels: the current values of up to two sensors, with quality dots.
MouseArea {
    id: compact

    property var widget

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property var reading1: widget.readings.find(r => r.sensorType === widget.cfg.compactSensor1)
                                    || widget.visibleReadings[0] || null
    readonly property var reading2: widget.cfg.compactSensor2 === "" ? null
                                    : widget.readings.find(r => r.sensorType === widget.cfg.compactSensor2) || null

    Layout.minimumWidth: vertical ? -1 : row.implicitWidth
    Layout.minimumHeight: vertical ? row.implicitHeight : -1

    hoverEnabled: true
    onClicked: widget.expanded = !widget.expanded

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        // First sensor
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                implicitWidth: Kirigami.Units.smallSpacing * 2
                implicitHeight: implicitWidth
                radius: width / 2
                color: compact.reading1
                       ? compact.widget.qualityColor(Sensors.quality(compact.reading1.sensorType, compact.reading1.value, compact.reading1.unit))
                       : Kirigami.Theme.disabledTextColor
            }

            PlasmaComponents3.Label {
                text: !compact.reading1 ? "–"
                      : Sensors.formatValue(compact.reading1.sensorType, compact.reading1.value)
                        + (compact.vertical ? "" : " " + Sensors.unitLabel(compact.reading1.unit))
            }
        }

        // Second sensor (if configured)
        RowLayout {
            visible: compact.reading2 !== null
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                implicitWidth: Kirigami.Units.smallSpacing * 2
                implicitHeight: implicitWidth
                radius: width / 2
                color: compact.reading2
                       ? compact.widget.qualityColor(Sensors.quality(compact.reading2.sensorType, compact.reading2.value, compact.reading2.unit))
                       : Kirigami.Theme.disabledTextColor
            }

            PlasmaComponents3.Label {
                text: !compact.reading2 ? "–"
                      : Sensors.formatValue(compact.reading2.sensorType, compact.reading2.value)
                        + (compact.vertical ? "" : " " + Sensors.unitLabel(compact.reading2.unit))
            }
        }
    }
}
