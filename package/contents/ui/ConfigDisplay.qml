import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/sensors.mjs" as Sensors

KCM.SimpleKCM {
    id: page

    property var cfg_visibleSensors: []
    property string cfg_compactSensor1
    property string cfg_compactSensor2
    property string cfg_layoutMode
    property string cfg_themeMode
    property alias cfg_showSparklines: sparklineCheck.checked
    property alias cfg_sparklineHours: sparklineSpin.value
    property alias cfg_showBattery: batteryCheck.checked
    property alias cfg_showLastUpdated: updatedCheck.checked

    // Sensors of the selected device, or every known sensor if no device is selected yet.
    readonly property var availableSensors: {
        const deviceSensors = Array.from(Plasmoid.configuration.deviceSensors);
        return deviceSensors.length > 0 ? deviceSensors : Sensors.SENSOR_TYPES;
    }

    readonly property var compactOptions: [{ text: i18n("First shown sensor"), value: "" }]
        .concat(availableSensors.map(type => ({ text: i18n(Sensors.info(type).name), value: type })))

    // An empty selection means "show every sensor".
    function isVisible(type) {
        return cfg_visibleSensors.length === 0 || cfg_visibleSensors.indexOf(type) !== -1;
    }

    function setVisible(type, visible) {
        const selected = availableSensors.filter(t => t === type ? visible : isVisible(t));
        // An empty list means "show all", so keep the last sensor selected.
        if (selected.length > 0) {
            cfg_visibleSensors = selected;
        }
    }

    Kirigami.FormLayout {
        QQC2.ButtonGroup { id: layoutGroup }
        QQC2.ButtonGroup { id: themeGroup }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Show sensors:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop

            Repeater {
                model: page.availableSensors
                delegate: QQC2.CheckBox {
                    required property string modelData
                    text: i18n(Sensors.info(modelData).name)
                    checked: page.isVisible(modelData)
                    onToggled: page.setVisible(modelData, checked)
                }
            }
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Panel shows (1st sensor):")
            model: page.compactOptions
            textRole: "text"
            currentIndex: Math.max(0, page.compactOptions.findIndex(o => o.value === page.cfg_compactSensor1))
            onActivated: index => page.cfg_compactSensor1 = page.compactOptions[index].value
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Panel shows (2nd sensor):")
            model: page.compactOptions
            textRole: "text"
            currentIndex: Math.max(0, page.compactOptions.findIndex(o => o.value === page.cfg_compactSensor2))
            onActivated: index => page.cfg_compactSensor2 = page.compactOptions[index].value
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.RadioButton {
            Kirigami.FormData.label: i18n("Layout:")
            QQC2.ButtonGroup.group: layoutGroup
            text: i18n("Grid")
            checked: page.cfg_layoutMode === "grid"
            onToggled: if (checked) page.cfg_layoutMode = "grid"
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: layoutGroup
            text: i18n("Vertical list")
            checked: page.cfg_layoutMode === "list"
            onToggled: if (checked) page.cfg_layoutMode = "list"
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: layoutGroup
            text: i18n("Horizontal row")
            checked: page.cfg_layoutMode === "row"
            onToggled: if (checked) page.cfg_layoutMode = "row"
        }

        QQC2.RadioButton {
            Kirigami.FormData.label: i18n("Colors:")
            QQC2.ButtonGroup.group: themeGroup
            text: i18n("Follow Plasma theme")
            checked: page.cfg_themeMode === "system"
            onToggled: if (checked) page.cfg_themeMode = "system"
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: themeGroup
            text: i18nc("@option:radio color scheme", "Light")
            checked: page.cfg_themeMode === "light"
            onToggled: if (checked) page.cfg_themeMode = "light"
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: themeGroup
            text: i18nc("@option:radio color scheme", "Dark")
            checked: page.cfg_themeMode === "dark"
            onToggled: if (checked) page.cfg_themeMode = "dark"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: sparklineCheck
            Kirigami.FormData.label: i18n("Trend lines:")
            text: i18n("Show a trend line in each tile")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Trend period:")
            enabled: sparklineCheck.checked
            QQC2.SpinBox {
                id: sparklineSpin
                from: 1
                to: Plasmoid.configuration.historyDays * 24
            }
            QQC2.Label {
                text: i18np("hour", "hours", sparklineSpin.value)
            }
        }

        QQC2.CheckBox {
            id: updatedCheck
            Kirigami.FormData.label: i18n("Footer:")
            text: i18n("Show last update time")
        }
        QQC2.CheckBox {
            id: batteryCheck
            text: i18n("Show battery level")
        }
    }
}
