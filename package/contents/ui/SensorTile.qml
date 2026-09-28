import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// One sensor: name, current value with a quality bar, and an optional trend line.
Rectangle {
    id: tile

    property string name
    property string valueText
    property string unitText
    property color qualityColor
    property string qualityLabel: ""
    property bool showSparkline: true
    property var points: []
    property real fromMs: 0
    property real toMs: 1
    property real maxGapMs: Infinity

    signal clicked()

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: (name + " " + valueText + " " + unitText + " " + qualityLabel).trim()
    Accessible.onPressAction: tile.clicked()
    Keys.onReturnPressed: tile.clicked()
    Keys.onSpacePressed: tile.clicked()

    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                   mouse.containsMouse || tile.activeFocus ? 0.09 : 0.045)
    border.width: tile.activeFocus ? 2 : 1
    border.color: tile.activeFocus || mouse.containsMouse
                  ? Kirigami.Theme.highlightColor
                  : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
    radius: Kirigami.Units.cornerRadius

    // Quality indicator
    Rectangle {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Kirigami.Units.smallSpacing }
        width: Math.max(3, Kirigami.Units.smallSpacing)
        radius: width / 2
        color: tile.qualityLabel !== "" ? tile.qualityColor : Kirigami.Theme.disabledTextColor
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing * 2
        anchors.leftMargin: Kirigami.Units.smallSpacing * 4
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: tile.name
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                visible: tile.qualityLabel !== ""
                text: tile.qualityLabel
                color: tile.qualityColor
                font: Kirigami.Theme.smallFont
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: tile.valueText
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.6
                font.bold: true
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignBaseline
                text: tile.unitText
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: tile.showSparkline

            Sparkline {
                anchors.fill: parent
                points: tile.points
                fromMs: tile.fromMs
                toMs: tile.toMs
                maxGapMs: tile.maxGapMs
                color: Kirigami.Theme.highlightColor
            }

            PlasmaComponents3.Label {
                anchors.centerIn: parent
                visible: tile.points.length < 2
                text: i18n("Collecting history…")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
