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

    // Config indices (0-3) of the sensors to show, in order. Index 0 is
    // always shown (falls back to the first visible reading when unset);
    // indices 1-3 are included only when explicitly configured ("none"
    // otherwise). This only depends on configuration, not live readings, so
    // the Repeater below doesn't get rebuilt on every periodic refresh.
    readonly property var slotIndices: {
        const configured = widget.cfg.compactSensors || [];
        const result = [0];
        for (let i = 1; i < 4; i++) {
            if ((configured[i] || "") !== "") {
                result.push(i);
            }
        }
        return result;
    }

    // Live reading for a given slot's config index, re-evaluated whenever
    // widget.readings changes (used from a delegate-local binding so only
    // that binding updates, not the whole Repeater).
    function slotReading(configIndex) {
        const configured = widget.cfg.compactSensors || [];
        const type = configured[configIndex] || "";
        const found = widget.readings.find(r => r.sensorType === type) || null;
        return configIndex === 0 ? (found || widget.visibleReadings[0] || null) : found;
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
        columns: compact.vertical ? 1 : compact.slotIndices.length
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.largeSpacing

        Repeater {
            model: compact.slotIndices

            delegate: RowLayout {
                id: sensorRow
                required property int modelData
                required property int index

                readonly property var reading: compact.slotReading(modelData)

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
                    color: sensorRow.reading
                           ? compact.widget.qualityColor(Sensors.quality(sensorRow.reading.sensorType, sensorRow.reading.value, sensorRow.reading.unit))
                           : Kirigami.Theme.disabledTextColor
                }

                PlasmaComponents3.Label {
                    text: !sensorRow.reading ? "–"
                          : Sensors.formatValue(sensorRow.reading.sensorType, sensorRow.reading.value)
                            + (compact.vertical ? "" : " " + Sensors.unitLabel(sensorRow.reading.unit))
                }

                // Hover tooltip names the sensor, since with several dots and
                // numbers side by side it's not always obvious which is which.
                HoverHandler {
                    id: hover
                }
                PlasmaComponents3.ToolTip.text: sensorRow.reading ? i18n(Sensors.info(sensorRow.reading.sensorType).name) : ""
                PlasmaComponents3.ToolTip.visible: hover.hovered && sensorRow.reading !== null
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }
}
