import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "code/sensors.mjs" as Sensors

// Shown in panels: the current values of up to four sensors, with quality dots.
MouseArea {
    id: compact

    property var widget

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Up to 4 sensor slots. Slot 1 falls back to the first visible reading
    // when unset; slots 2-4 are skipped entirely when unset ("none").
    readonly property var slots: {
        const configured = widget.cfg.compactSensors || [];
        const result = [];
        for (let i = 0; i < 4; i++) {
            const type = configured[i] || "";
            if (i === 0) {
                const reading = widget.readings.find(r => r.sensorType === type)
                                || widget.visibleReadings[0] || null;
                result.push(reading);
            } else if (type !== "") {
                result.push(widget.readings.find(r => r.sensorType === type) || null);
            }
        }
        return result;
    }

    Layout.minimumWidth: vertical ? -1 : row.implicitWidth
    Layout.minimumHeight: vertical ? row.implicitHeight : -1

    hoverEnabled: true
    onClicked: widget.expanded = !widget.expanded

    // Horizontal panels lay sensors out side by side; vertical (thin) panels
    // stack them instead of squeezing everything into a narrow row.
    GridLayout {
        id: row
        anchors.centerIn: parent
        columns: compact.vertical ? 1 : compact.slots.length
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        Repeater {
            model: compact.slots

            delegate: RowLayout {
                id: sensorRow
                required property var modelData
                required property int index

                spacing: Kirigami.Units.smallSpacing

                // A thin divider between sensors makes multi-sensor panels
                // (up to 4) easier to scan than spacing alone.
                Kirigami.Separator {
                    visible: sensorRow.index > 0
                    Layout.fillHeight: visible && !compact.vertical
                    Layout.fillWidth: visible && compact.vertical
                    Layout.preferredHeight: !visible ? 0 : (compact.vertical ? 1 : -1)
                    Layout.preferredWidth: !visible ? 0 : (compact.vertical ? -1 : 1)
                }

                Rectangle {
                    implicitWidth: Kirigami.Units.smallSpacing * 2
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: sensorRow.modelData
                           ? compact.widget.qualityColor(Sensors.quality(sensorRow.modelData.sensorType, sensorRow.modelData.value, sensorRow.modelData.unit))
                           : Kirigami.Theme.disabledTextColor
                }

                PlasmaComponents3.Label {
                    text: !sensorRow.modelData ? "–"
                          : Sensors.formatValue(sensorRow.modelData.sensorType, sensorRow.modelData.value)
                            + (compact.vertical ? "" : " " + Sensors.unitLabel(sensorRow.modelData.unit))
                }

                // Hover tooltip names the sensor, since with several dots and
                // numbers side by side it's not always obvious which is which.
                HoverHandler {
                    id: hover
                }
                PlasmaComponents3.ToolTip.text: sensorRow.modelData ? i18n(Sensors.info(sensorRow.modelData.sensorType).name) : ""
                PlasmaComponents3.ToolTip.visible: hover.hovered && sensorRow.modelData !== null
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
