import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.LocalStorage
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/history.mjs" as History

KCM.SimpleKCM {
    id: page

    property alias cfg_historyDays: daysSpin.value

    // Same database as main.qml
    readonly property var db: LocalStorage.openDatabaseSync("AirthingsWidget", "", "Airthings widget history", 10 * 1024 * 1024)
    readonly property string serial: Plasmoid.configuration.deviceSerial
    readonly property int sensorCount: Math.max(1, Plasmoid.configuration.deviceSensors.length)
    readonly property int estimatedSamples: Math.round(24 * 60 / Plasmoid.configuration.refreshMinutes) * sensorCount * daysSpin.value
    property int storedSamples: 0

    function updateCount() {
        storedSamples = serial !== "" ? History.count(db, serial) : 0;
    }

    Component.onCompleted: {
        History.init(db);
        updateCount();
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Keep history for:")
            QQC2.SpinBox {
                id: daysSpin
                from: 1
                to: 90
            }
            QQC2.Label {
                text: i18np("day", "days", daysSpin.value)
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Estimated size:")
            text: i18np("About %1 sample", "About %1 samples", page.estimatedSamples)
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Stored now:")
            text: i18np("%1 sample", "%1 samples", page.storedSamples)
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18n("History is recorded only while the widget is running, so periods when the computer was off appear as gaps. Values are stored in the units they were fetched in. Older samples are removed at the next refresh.")
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Device history:")
            text: i18n("Clear History…")
            icon.name: "edit-clear-history"
            enabled: page.storedSamples > 0
            onClicked: confirmDialog.open()
        }
    }

    Kirigami.PromptDialog {
        id: confirmDialog
        title: i18n("Clear History")
        subtitle: i18n("Delete all stored readings of this device? This cannot be undone.")
        standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
        onAccepted: {
            History.clear(page.db, page.serial);
            page.updateCount();
        }
    }
}
