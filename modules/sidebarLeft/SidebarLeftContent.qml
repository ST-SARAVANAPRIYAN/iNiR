import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Qt.labs.synchronizer

Item {
    id: root
    required property var scopeRoot
    property int sidebarPadding: 10
    property bool isDetached: scopeRoot?.detach ?? false
    property int maxContentWidth: 800 // Max width for comfortable reading in detached mode
    anchors.fill: parent
    property bool aiChatEnabled: (Config.options?.policies?.ai ?? 0) !== 0
    property bool translatorEnabled: (Config.options?.sidebar?.translator?.enable ?? false)
    property bool animeEnabled: (Config.options?.policies?.weeb ?? 0) !== 0
    property bool animeCloset: (Config.options?.policies?.weeb ?? 0) === 2
    property bool wallhavenEnabled: Config.options.sidebar?.wallhaven?.enable !== false
    property bool widgetsEnabled: Config.options?.sidebar?.widgets?.enable ?? true
    property var tabButtonList: [
        ...(root.widgetsEnabled ? [{"icon": "widgets", "name": Translation.tr("Widgets")}] : []),
        ...(root.aiChatEnabled ? [{"icon": "neurology", "name": Translation.tr("Intelligence")}] : []),
        ...(root.translatorEnabled ? [{"icon": "translate", "name": Translation.tr("Translator")}] : []),
        ...((root.animeEnabled && !root.animeCloset) ? [{"icon": "bookmark_heart", "name": Translation.tr("Anime")}] : []),
        ...(root.wallhavenEnabled ? [{"icon": "image", "name": Translation.tr("Wallhaven")}] : [])
    ]
    property int tabCount: swipeView.count

    function focusActiveItem() {
        swipeView.currentItem.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.modifiers === Qt.ControlModifier) {
            if (event.key === Qt.Key_PageDown) {
                swipeView.incrementCurrentIndex()
                event.accepted = true;
            }
            else if (event.key === Qt.Key_PageUp) {
                swipeView.decrementCurrentIndex()
                event.accepted = true;
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: sidebarPadding
            topMargin: Appearance.inirEverywhere ? sidebarPadding + 6 : sidebarPadding
            leftMargin: root.isDetached ? Math.max(sidebarPadding, (parent.width - root.maxContentWidth) / 2) : sidebarPadding
            rightMargin: root.isDetached ? Math.max(sidebarPadding, (parent.width - root.maxContentWidth) / 2) : sidebarPadding
        }
        spacing: Appearance.inirEverywhere ? sidebarPadding + 4 : sidebarPadding

        Toolbar {
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                maxWidth: Math.max(0, root.width - (root.sidebarPadding * 2) - 16)
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                 : Appearance.auroraEverywhere ? "transparent" 
                 : Appearance.colors.colLayer1
            border.width: Appearance.inirEverywhere ? 1 : 0
            border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"

            SwipeView { // Content pages
                id: swipeView
                anchors.fill: parent
                spacing: 10
                currentIndex: tabBar.currentIndex
                // Bloquear swipe cuando se está arrastrando un widget
                interactive: !(currentItem?.editMode ?? false)

                onCurrentIndexChanged: {
                    if (root.aiChatEnabled && swipeView.currentIndex === 0) {
                        Ai.ensureInitialized()
                    }
                }

                clip: true
                layer.enabled: true
                layer.effect: GE.OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                contentChildren: [
                    ...(root.widgetsEnabled ? [widgetsView.createObject()] : []),
                    ...((root.aiChatEnabled || (!root.translatorEnabled && !root.animeEnabled && !root.wallhavenEnabled && !root.widgetsEnabled)) ? [aiChat.createObject()] : []),
                    ...(root.translatorEnabled ? [translator.createObject()] : []),
                    ...(root.animeEnabled ? [anime.createObject()] : []),
                    ...(root.wallhavenEnabled ? [wallhaven.createObject()] : [])
                ]
            }
        }

        Component {
            id: widgetsView
            WidgetsView {}
        }
        Component {
            id: aiChat
            AiChat {}
        }
        Component {
            id: translator
            Translator {}
        }
        Component {
            id: anime
            Anime {}
        }
        Component {
            id: wallhaven
            WallhavenView {}
        }
        
    }
}