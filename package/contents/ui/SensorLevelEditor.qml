import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Frame {
    id: editor

    required property string sensorName
    required property string unit
    required property int decimals
    required property var levels

    signal levelsEdited(var levels)
    signal resetRequested()

    readonly property bool inputsValid: goodMin.acceptableInput && goodMax.acceptableInput
                                        && fairMin.acceptableInput && fairMax.acceptableInput
    readonly property var enteredLevels: ({
        goodMin: parse(goodMin.text),
        goodMax: parse(goodMax.text),
        fairMin: parse(fairMin.text),
        fairMax: parse(fairMax.text),
    })
    readonly property bool rangeValid: inputsValid
                                       && enteredLevels.fairMin <= enteredLevels.goodMin
                                       && enteredLevels.goodMin <= enteredLevels.goodMax
                                       && enteredLevels.goodMax <= enteredLevels.fairMax

    Layout.fillWidth: true

    function parse(text) {
        return Number.fromLocaleString(Qt.locale(), text);
    }

    function format(value) {
        return Number(value).toLocaleString(Qt.locale(), "f", decimals);
    }

    function sync() {
        if (goodMin.activeFocus || goodMax.activeFocus || fairMin.activeFocus || fairMax.activeFocus) {
            return;
        }
        goodMin.text = format(levels.goodMin);
        goodMax.text = format(levels.goodMax);
        fairMin.text = format(levels.fairMin);
        fairMax.text = format(levels.fairMax);
    }

    function commit() {
        if (rangeValid) {
            levelsEdited(enteredLevels);
        }
    }

    onLevelsChanged: sync()
    Component.onCompleted: sync()

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("%1 (%2)", editor.sensorName, editor.unit)
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                text: i18n("Reset")
                display: QQC2.AbstractButton.TextBesideIcon
                onClicked: editor.resetRequested()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Level")
                font.bold: true
            }
            QQC2.Label {
                text: i18n("Minimum")
                font.bold: true
            }
            QQC2.Label {
                text: i18n("Maximum")
                font.bold: true
            }

            QQC2.Label {
                text: i18n("Good")
            }
            LevelTextField {
                id: goodMin
                decimals: editor.decimals
                onEditingFinished: editor.commit()
            }
            LevelTextField {
                id: goodMax
                decimals: editor.decimals
                onEditingFinished: editor.commit()
            }

            QQC2.Label {
                text: i18n("Fair")
            }
            LevelTextField {
                id: fairMin
                decimals: editor.decimals
                onEditingFinished: editor.commit()
            }
            LevelTextField {
                id: fairMax
                decimals: editor.decimals
                onEditingFinished: editor.commit()
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !editor.rangeValid
            type: Kirigami.MessageType.Error
            text: i18n("Enter valid numbers ordered as: fair minimum ≤ good minimum ≤ good maximum ≤ fair maximum.")
        }
    }
}
