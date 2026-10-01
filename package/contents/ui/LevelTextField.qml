import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

QQC2.TextField {
    required property int decimals

    Layout.fillWidth: true
    inputMethodHints: Qt.ImhFormattedNumbersOnly
    selectByMouse: true
    validator: DoubleValidator {
        bottom: -1000000
        top: 1000000
        decimals: parent.decimals
        notation: DoubleValidator.StandardNotation
        locale: Qt.locale().name
    }
}
