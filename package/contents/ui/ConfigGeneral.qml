import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

import "code/api.mjs" as Api

KCM.SimpleKCM {
    id: page

    property string cfg_clientId
    property string cfg_clientSecret
    property string cfg_accountId
    property string cfg_deviceSerial
    property string cfg_deviceName
    property var cfg_deviceSensors: []
    property alias cfg_refreshMinutes: refreshSpin.value
    property string cfg_unitSystem

    readonly property bool connected: cfg_clientId !== "" && cfg_clientSecret !== "" && cfg_accountId !== ""

    property var devices: []            // [{ serial, name, sensors, label }]
    property bool busy: false

    function device(serial, name, sensors) {
        return { serial, name: name || serial, sensors: sensors || [], label: name ? `${name} (${serial})` : serial };
    }

    function selectDevice(d) {
        cfg_deviceSerial = d.serial;
        cfg_deviceName = d.name;
        cfg_deviceSensors = d.sensors;
    }

    function showStatus(type, text) {
        statusMessage.type = type;
        statusMessage.text = text;
        statusMessage.visible = true;
    }

    // Checks the credentials and fetches the devices of the first account.
    // Calls onSuccess(accountId, devices) or onError(message).
    function loadDevices(clientId, clientSecret, onSuccess, onError) {
        busy = true;
        const client = new Api.Client(clientId, clientSecret);
        let accountId = "";
        client.accounts().then(accounts => {
            if (accounts.length === 0) {
                throw { noAccount: true };
            }
            accountId = accounts[0].id;
            return client.devices(accountId);
        }).then(list => {
            busy = false;
            onSuccess(accountId, list.map(d => device(d.serialNumber, d.name, d.sensors)));
        }).catch(error => {
            busy = false;
            onError(error.noAccount ? i18n("No Airthings account found for these credentials")
                  : error.auth ? i18n("Invalid client credentials")
                  : i18n("Error: %1", error.message ? i18n(error.message) : String(error)));
        });
    }

    function applyDevices(accountId, list) {
        cfg_accountId = accountId;
        devices = list;
        if (list.length === 0) {
            showStatus(Kirigami.MessageType.Warning, i18n("No devices found in this account"));
            return;
        }
        selectDevice(list.find(d => d.serial === cfg_deviceSerial) || list[0]);
        showStatus(Kirigami.MessageType.Positive, i18np("Found %1 device", "Found %1 devices", list.length));
    }

    function reloadDevices() {
        loadDevices(cfg_clientId, cfg_clientSecret, applyDevices,
                    message => showStatus(Kirigami.MessageType.Error, message));
    }

    Component.onCompleted: {
        // Until devices are loaded again, show the saved one.
        if (cfg_deviceSerial !== "") {
            devices = [device(cfg_deviceSerial, cfg_deviceName, cfg_deviceSensors)];
        }
    }

    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: i18n("Account:")

            QQC2.Label {
                visible: page.connected
                text: i18n("Connected (client ID %1…)", page.cfg_clientId.substring(0, 8))
            }
            QQC2.Button {
                text: page.connected ? i18n("Change Credentials…") : i18n("Connect to Airthings…")
                icon.name: page.connected ? "document-edit" : "network-connect"
                enabled: !page.busy
                onClicked: credentialsDialog.open()
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Device:")

            QQC2.ComboBox {
                Layout.fillWidth: true
                enabled: page.devices.length > 0
                model: page.devices
                textRole: "label"
                currentIndex: page.devices.findIndex(d => d.serial === page.cfg_deviceSerial)
                displayText: currentIndex === -1 ? i18n("None") : currentText
                onActivated: index => page.selectDevice(page.devices[index])
            }

            QQC2.ToolButton {
                icon.name: "view-refresh"
                enabled: page.connected && !page.busy
                onClicked: page.reloadDevices()
                QQC2.ToolTip.text: i18n("Reload devices")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                Accessible.name: QQC2.ToolTip.text
            }
        }

        Kirigami.InlineMessage {
            id: statusMessage
            Layout.fillWidth: true
            visible: false
            showCloseButton: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Refresh every:")
            QQC2.SpinBox {
                id: refreshSpin
                from: 1
                to: 60
            }
            QQC2.Label {
                text: i18np("minute", "minutes", refreshSpin.value)
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: i18n("The Airthings API allows 120 requests per hour. Devices upload new readings about every 5 minutes.")
            font: Kirigami.Theme.smallFont
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Units:")
            model: [i18n("Metric"), i18n("Imperial")]
            currentIndex: page.cfg_unitSystem === "imperial" ? 1 : 0
            onActivated: index => page.cfg_unitSystem = index === 1 ? "imperial" : "metric"
        }
    }

    // Credentials are saved only after they have been checked against the API.
    Kirigami.Dialog {
        id: credentialsDialog

        property string errorText: ""
        readonly property bool canConnect: !page.busy && clientIdField.text.trim() !== ""
                                           && clientSecretField.text.trim() !== ""

        function connect() {
            if (!canConnect) {
                return;
            }
            const clientId = clientIdField.text.trim();
            const clientSecret = clientSecretField.text.trim();
            errorText = "";
            page.loadDevices(clientId, clientSecret, (accountId, list) => {
                if (!credentialsDialog.visible) {
                    return; // cancelled while connecting
                }
                page.cfg_clientId = clientId;
                page.cfg_clientSecret = clientSecret;
                page.applyDevices(accountId, list);
                credentialsDialog.close();
            }, message => credentialsDialog.errorText = message);
        }

        title: i18n("Airthings API Credentials")
        preferredWidth: Kirigami.Units.gridUnit * 25
        padding: Kirigami.Units.largeSpacing
        standardButtons: Kirigami.Dialog.Cancel
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Connect")
                icon.name: "network-connect"
                enabled: credentialsDialog.canConnect
                onTriggered: credentialsDialog.connect()
            }
        ]

        onOpened: {
            clientIdField.text = page.cfg_clientId;
            clientSecretField.text = page.cfg_clientSecret;
            errorText = "";
            clientIdField.forceActiveFocus();
        }

        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

                QQC2.TextField {
                    id: clientIdField
                    Kirigami.FormData.label: i18n("Client ID:")
                    Layout.fillWidth: true
                    enabled: !page.busy
                    onAccepted: credentialsDialog.connect()
                }

                Kirigami.PasswordField {
                    id: clientSecretField
                    Kirigami.FormData.label: i18n("Client secret:")
                    Layout.fillWidth: true
                    enabled: !page.busy
                    onAccepted: credentialsDialog.connect()
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                text: i18n("Create an API client (flow type: Client Credentials) in the <a href=\"%1\">Airthings dashboard</a>. The secret is stored unencrypted in your Plasma configuration.",
                           "https://consumer-api-doc.airthings.com/dashboard")
                onLinkActivated: link => Qt.openUrlExternally(link)
                font: Kirigami.Theme.smallFont
            }

            Kirigami.InlineMessage {
                Layout.fillWidth: true
                type: Kirigami.MessageType.Error
                text: credentialsDialog.errorText
                visible: text !== ""
            }

            RowLayout {
                opacity: page.busy ? 1 : 0     // keeps its space so the dialog does not resize
                QQC2.BusyIndicator {
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                }
                QQC2.Label {
                    text: i18n("Connecting to Airthings…")
                }
            }
        }
    }
}
