import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/sensors.mjs" as Sensors

KCM.SimpleKCM {
    id: page

    property real cfg_radonBqGoodMin
    property real cfg_radonBqGoodMax
    property real cfg_radonBqFairMin
    property real cfg_radonBqFairMax
    property real cfg_radonPciGoodMin
    property real cfg_radonPciGoodMax
    property real cfg_radonPciFairMin
    property real cfg_radonPciFairMax
    property real cfg_co2PpmGoodMin
    property real cfg_co2PpmGoodMax
    property real cfg_co2PpmFairMin
    property real cfg_co2PpmFairMax
    property real cfg_vocPpbGoodMin
    property real cfg_vocPpbGoodMax
    property real cfg_vocPpbFairMin
    property real cfg_vocPpbFairMax
    property real cfg_pm1MgpcGoodMin
    property real cfg_pm1MgpcGoodMax
    property real cfg_pm1MgpcFairMin
    property real cfg_pm1MgpcFairMax
    property real cfg_pm25MgpcGoodMin
    property real cfg_pm25MgpcGoodMax
    property real cfg_pm25MgpcFairMin
    property real cfg_pm25MgpcFairMax
    property real cfg_humidityPctGoodMin
    property real cfg_humidityPctGoodMax
    property real cfg_humidityPctFairMin
    property real cfg_humidityPctFairMax
    property real cfg_tempCGoodMin
    property real cfg_tempCGoodMax
    property real cfg_tempCFairMin
    property real cfg_tempCFairMax
    property real cfg_tempFGoodMin
    property real cfg_tempFGoodMax
    property real cfg_tempFFairMin
    property real cfg_tempFFairMax

    readonly property var defaults: ({
        radonBq: { goodMin: 0, goodMax: 100, fairMin: 0, fairMax: 150 },
        radonPci: { goodMin: 0, goodMax: 2.7, fairMin: 0, fairMax: 4 },
        co2Ppm: { goodMin: 0, goodMax: 800, fairMin: 0, fairMax: 1000 },
        vocPpb: { goodMin: 0, goodMax: 250, fairMin: 0, fairMax: 2000 },
        pm1Mgpc: { goodMin: 0, goodMax: 10, fairMin: 0, fairMax: 25 },
        pm25Mgpc: { goodMin: 0, goodMax: 10, fairMin: 0, fairMax: 25 },
        humidityPct: { goodMin: 30, goodMax: 60, fairMin: 25, fairMax: 70 },
        tempC: { goodMin: 18, goodMax: 25, fairMin: 16, fairMax: 27 },
        tempF: { goodMin: 64, goodMax: 77, fairMin: 61, fairMax: 81 },
    })

    readonly property var availableSensors: {
        const configured = Array.from(Plasmoid.configuration.deviceSensors);
        return configured.length > 0 ? configured : Sensors.SENSOR_TYPES;
    }
    readonly property var visibleDefinitions: Sensors.LEVEL_DEFINITIONS.filter(definition =>
        availableSensors.indexOf(definition.type) !== -1 && unitIsVisible(definition.unit))

    function unitIsVisible(unit) {
        if (unit === "bq" || unit === "c") {
            return Plasmoid.configuration.unitSystem !== "imperial";
        }
        if (unit === "pci" || unit === "f") {
            return Plasmoid.configuration.unitSystem === "imperial";
        }
        return true;
    }

    function levels(definition) {
        const key = "cfg_" + definition.key;
        return {
            goodMin: page[key + "GoodMin"],
            goodMax: page[key + "GoodMax"],
            fairMin: page[key + "FairMin"],
            fairMax: page[key + "FairMax"],
        };
    }

    function setLevels(definition, values) {
        const key = "cfg_" + definition.key;
        page[key + "GoodMin"] = values.goodMin;
        page[key + "GoodMax"] = values.goodMax;
        page[key + "FairMin"] = values.fairMin;
        page[key + "FairMax"] = values.fairMax;
    }

    function resetSensor(type) {
        for (const definition of Sensors.LEVEL_DEFINITIONS) {
            if (definition.type === type) {
                setLevels(definition, defaults[definition.key]);
            }
        }
    }

    function resetAll() {
        for (const definition of Sensors.LEVEL_DEFINITIONS) {
            setLevels(definition, defaults[definition.key]);
        }
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: i18n("Customize the inclusive value ranges used to classify readings. Values outside the fair range are shown as poor.")
        }

        Repeater {
            model: page.visibleDefinitions

            delegate: SensorLevelEditor {
                required property var modelData

                sensorName: i18n(Sensors.info(modelData.type).name)
                unit: Sensors.unitLabel(modelData.unit)
                decimals: modelData.decimals
                levels: page.levels(modelData)
                onLevelsEdited: values => page.setLevels(modelData, values)
                onResetRequested: page.resetSensor(modelData.type)
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignRight
            text: i18n("Reset All Levels")
            icon.name: "edit-undo"
            onClicked: page.resetAll()
        }
    }
}
