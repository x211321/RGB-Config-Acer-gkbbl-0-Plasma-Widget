import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.5 as QtControls
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

Kirigami.FormLayout {
    id: page
    property alias cfg_customIconColor: customIconColor.color
    property alias cfg_showHeader: showHeader.checked

    RowLayout {
        Kirigami.FormData.label:i18n("Show header:")

        QtControls.CheckBox {
            id: showHeader
        }
    }

    RowLayout {
        Kirigami.FormData.label:i18n("Tray icon color:")

        KQuickControls.ColorButton {
            id: customIconColor
        }
    }

}
