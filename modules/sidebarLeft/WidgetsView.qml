pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.sidebarLeft.widgets
import qs.services

Item {
    id: root
    
    // Exponer editMode para bloquear swipe del SwipeView padre
    readonly property bool editMode: widgetContainer.editMode

    Flickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Bloquear scroll horizontal cuando se arrastra widget
        interactive: !root.editMode

        ColumnLayout {
            id: mainColumn
            width: flickable.width
            spacing: 0

            // Time header (always at top)
            GlanceHeader {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
            }

            // Draggable widgets container
            DraggableWidgetContainer {
                id: widgetContainer
                Layout.fillWidth: true
            }

            Item { Layout.preferredHeight: 12 }
        }
    }
}
