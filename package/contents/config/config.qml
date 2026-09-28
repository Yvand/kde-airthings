import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Display")
        icon: "preferences-desktop-color"
        source: "ConfigDisplay.qml"
    }
    ConfigCategory {
        name: i18n("History")
        icon: "view-history"
        source: "ConfigHistory.qml"
    }
}
