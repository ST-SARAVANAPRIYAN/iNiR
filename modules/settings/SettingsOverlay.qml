import qs
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

/**
 * Settings UI as a layer shell overlay panel.
 * Allows users to see live changes to the shell (sidebars, bar, etc.)
 * without opening a separate window. Loaded by the main shell when
 * Config.options.settingsUi.overlayMode is true.
 */
Scope {
    id: root

    property bool settingsOpen: GlobalStates.settingsOverlayOpen ?? false

    // Keep alive after first open for instant re-open
    property bool _everOpened: false

    Connections {
        target: GlobalStates
        function onSettingsOverlayOpenChanged() {
            if (GlobalStates.settingsOverlayOpen) {
                root._everOpened = true
            }
        }
    }

    Loader {
        id: panelLoader
        active: root._everOpened

        sourceComponent: PanelWindow {
            id: settingsPanel

            visible: GlobalStates.settingsOverlayOpen ?? false

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:settingsOverlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Focus grab for Hyprland
            CompositorFocusGrab {
                id: grab
                windows: [settingsPanel]
                active: false
                onCleared: () => {
                    if (!active) GlobalStates.settingsOverlayOpen = false
                }
            }

            Connections {
                target: GlobalStates
                function onSettingsOverlayOpenChanged() {
                    grabTimer.restart()
                }
            }

            Timer {
                id: grabTimer
                interval: 100
                onTriggered: grab.active = (GlobalStates.settingsOverlayOpen ?? false)
            }

            // ── Scrim backdrop ──
            Rectangle {
                id: scrimBg
                anchors.fill: parent
                color: Appearance.colors.colScrim
                opacity: (GlobalStates.settingsOverlayOpen ?? false) ? 0.45 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.settingsOverlayOpen = false
                }
            }

            // ── Floating settings card ──
            Rectangle {
                id: settingsCard

                readonly property real maxCardWidth: Math.min(1100, settingsPanel.width * 0.88)
                readonly property real maxCardHeight: Math.min(850, settingsPanel.height * 0.88)

                anchors.centerIn: parent
                width: maxCardWidth
                height: maxCardHeight
                radius: Appearance.rounding.windowRounding
                color: Appearance.m3colors.m3background
                clip: true

                border.width: Appearance.inirEverywhere ? 1 : 0
                border.color: Appearance.inirEverywhere
                    ? (Appearance.inir?.colBorder ?? Appearance.colors.colLayer0Border)
                    : "transparent"

                // Scale + fade animation
                opacity: (GlobalStates.settingsOverlayOpen ?? false) ? 1 : 0
                scale: (GlobalStates.settingsOverlayOpen ?? false) ? 1.0 : 0.92

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveEnter.duration
                        easing.type: Easing.OutCubic
                    }
                }

                // Shadow
                layer.enabled: !Appearance.auroraEverywhere
                layer.effect: DropShadow {
                    color: Qt.rgba(0, 0, 0, 0.35)
                    radius: 24
                    samples: 25
                    verticalOffset: 8
                    horizontalOffset: 0
                }

                // Prevent clicks from closing
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                // ── Main content ──
                ColumnLayout {
                    id: mainLayout
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 8

                    // ── Title bar ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 4
                        spacing: 8

                        MaterialSymbol {
                            text: "settings"
                            iconSize: Appearance.font.pixelSize.huge
                            color: Appearance.m3colors.m3primary
                        }

                        StyledText {
                            text: Translation.tr("Settings")
                            font {
                                family: Appearance.font.family.title
                                pixelSize: Appearance.font.pixelSize.title
                                variableAxes: Appearance.font.variableAxes.title
                            }
                            color: Appearance.colors.colOnLayer0
                            Layout.fillWidth: true
                        }

                        // Search field
                        Rectangle {
                            Layout.preferredWidth: Math.min(300, settingsCard.width * 0.3)
                            Layout.preferredHeight: 36
                            radius: Appearance.rounding.full
                            color: overlaySearchField.activeFocus
                                ? Appearance.colors.colLayer1
                                : Appearance.m3colors.m3surfaceContainerLow
                            border.width: overlaySearchField.activeFocus ? 2 : 1
                            border.color: overlaySearchField.activeFocus
                                ? Appearance.colors.colPrimary
                                : Appearance.m3colors.m3outlineVariant

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 6

                                MaterialSymbol {
                                    text: "search"
                                    iconSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colSubtext
                                }

                                TextInput {
                                    id: overlaySearchField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: Text.AlignVCenter
                                    color: Appearance.colors.colOnLayer1
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                    clip: true

                                    property string placeholderText: Translation.tr("Search settings...")

                                    // We don't wire up the full search system here;
                                    // the search index is in settings.qml's ApplicationWindow.
                                    // For overlay mode, we forward to the loaded page's search if available.
                                }

                                StyledText {
                                    visible: overlaySearchField.text.length === 0 && !overlaySearchField.activeFocus
                                    text: overlaySearchField.placeholderText
                                    font {
                                        family: Appearance.font.family.main
                                        pixelSize: Appearance.font.pixelSize.small
                                    }
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Close button
                        RippleButton {
                            buttonRadius: Appearance.rounding.full
                            implicitWidth: 36
                            implicitHeight: 36
                            onClicked: GlobalStates.settingsOverlayOpen = false
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                text: "close"
                                iconSize: 20
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }

                    // ── Navigation + Content ──
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        // Navigation rail (compact)
                        Rectangle {
                            id: navColumn
                            Layout.fillHeight: true
                            Layout.preferredWidth: 56
                            radius: Appearance.rounding.normal
                            color: Appearance.m3colors.m3surfaceContainerLow

                            Flickable {
                                anchors.fill: parent
                                anchors.margins: 4
                                contentHeight: navCol.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: navCol
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: overlayPages
                                        delegate: RippleButton {
                                            id: navBtn
                                            required property int index
                                            required property var modelData

                                            Layout.fillWidth: true
                                            implicitHeight: 48
                                            buttonRadius: Appearance.rounding.small
                                            toggled: overlayCurrentPage === index
                                            colBackground: toggled
                                                ? Appearance.colors.colPrimaryContainer
                                                : "transparent"
                                            colBackgroundHover: Appearance.colors.colLayer1Hover

                                            onClicked: overlayCurrentPage = index

                                            contentItem: ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2

                                                MaterialSymbol {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.icon
                                                    iconSize: 20
                                                    color: navBtn.toggled
                                                        ? Appearance.colors.colOnPrimaryContainer
                                                        : Appearance.colors.colOnSurfaceVariant
                                                    rotation: modelData.iconRotation || 0
                                                }

                                                StyledText {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    text: modelData.shortName || ""
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    color: navBtn.toggled
                                                        ? Appearance.colors.colOnPrimaryContainer
                                                        : Appearance.colors.colOnSurfaceVariant
                                                    visible: text.length > 0
                                                }
                                            }

                                            StyledToolTip {
                                                text: modelData.name
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Content area
                        Rectangle {
                            id: overlayContentContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Appearance.rounding.normal
                            color: Appearance.m3colors.m3surfaceContainerLow
                            clip: true

                            // Page stack
                            Item {
                                id: overlayPagesStack
                                anchors.fill: parent

                                property var visitedPages: ({})
                                property int preloadIndex: 0

                                Connections {
                                    target: settingsCard
                                    function onVisibleChanged() {
                                        if (settingsCard.visible) {
                                            // Mark current page
                                            overlayPagesStack.visitedPages[overlayCurrentPage] = true
                                            overlayPagesStack.visitedPagesChanged()
                                            // Start preloading
                                            overlayPreloadTimer.start()
                                        }
                                    }
                                }

                                Component.onCompleted: {
                                    visitedPages[overlayCurrentPage] = true
                                }

                                Timer {
                                    id: overlayPreloadTimer
                                    interval: 200
                                    repeat: true
                                    onTriggered: {
                                        if (overlayPagesStack.preloadIndex < overlayPages.length) {
                                            if (!overlayPagesStack.visitedPages[overlayPagesStack.preloadIndex]) {
                                                overlayPagesStack.visitedPages[overlayPagesStack.preloadIndex] = true
                                                overlayPagesStack.visitedPagesChanged()
                                            }
                                            overlayPagesStack.preloadIndex++
                                        } else {
                                            overlayPreloadTimer.stop()
                                        }
                                    }
                                }

                                Repeater {
                                    model: overlayPages.length
                                    delegate: Loader {
                                        id: overlayPageLoader
                                        required property int index
                                        anchors.fill: parent
                                        active: Config.ready && (overlayPagesStack.visitedPages[index] === true)
                                        asynchronous: index !== overlayCurrentPage
                                        source: overlayPages[index].component
                                        visible: index === overlayCurrentPage && status === Loader.Ready
                                        opacity: visible ? 1 : 0

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveFast.duration
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Escape key handler
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.settingsOverlayOpen = false
                        event.accepted = true
                    } else if (event.modifiers === Qt.ControlModifier) {
                        if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab) {
                            overlayCurrentPage = (overlayCurrentPage + 1) % overlayPages.length
                            event.accepted = true
                        } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab) {
                            overlayCurrentPage = (overlayCurrentPage - 1 + overlayPages.length) % overlayPages.length
                            event.accepted = true
                        }
                    }
                }

                // Grab focus when opened
                Connections {
                    target: GlobalStates
                    function onSettingsOverlayOpenChanged() {
                        if (GlobalStates.settingsOverlayOpen) {
                            settingsCard.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }

    // ── Page definitions (same as settings.qml) ──
    property int overlayCurrentPage: 0

    property var overlayPages: [
        {
            name: Translation.tr("Quick"),
            shortName: "",
            icon: "instant_mix",
            component: Quickshell.shellPath("modules/settings/QuickConfig.qml")
        },
        {
            name: Translation.tr("General"),
            shortName: "",
            icon: "browse",
            component: Quickshell.shellPath("modules/settings/GeneralConfig.qml")
        },
        {
            name: Translation.tr("Bar"),
            shortName: "",
            icon: "toast",
            iconRotation: 180,
            component: Quickshell.shellPath("modules/settings/BarConfig.qml")
        },
        {
            name: Translation.tr("Background"),
            shortName: "",
            icon: "texture",
            component: Quickshell.shellPath("modules/settings/BackgroundConfig.qml")
        },
        {
            name: Translation.tr("Themes"),
            shortName: "",
            icon: "palette",
            component: Quickshell.shellPath("modules/settings/ThemesConfig.qml")
        },
        {
            name: Translation.tr("Interface"),
            shortName: "",
            icon: "bottom_app_bar",
            component: Quickshell.shellPath("modules/settings/InterfaceConfig.qml")
        },
        {
            name: Translation.tr("Services"),
            shortName: "",
            icon: "settings",
            component: Quickshell.shellPath("modules/settings/ServicesConfig.qml")
        },
        {
            name: Translation.tr("Advanced"),
            shortName: "",
            icon: "construction",
            component: Quickshell.shellPath("modules/settings/AdvancedConfig.qml")
        },
        {
            name: Translation.tr("Shortcuts"),
            shortName: "",
            icon: "keyboard",
            component: Quickshell.shellPath("modules/settings/CheatsheetConfig.qml")
        },
        {
            name: Translation.tr("Modules"),
            shortName: "",
            icon: "extension",
            component: Quickshell.shellPath("modules/settings/ModulesConfig.qml")
        },
        {
            name: Translation.tr("Waffle Style"),
            shortName: "",
            icon: "window",
            component: Quickshell.shellPath("modules/settings/WaffleConfig.qml")
        },
        {
            name: Translation.tr("About"),
            shortName: "",
            icon: "info",
            component: Quickshell.shellPath("modules/settings/About.qml")
        }
    ]

    // ── IPC handler — settings target is in shell.qml but we provide toggle ──
    // The shell.qml IPC handler decides which mode to use based on config.
}
