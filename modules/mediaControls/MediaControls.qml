pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: Mpris.players.values.filter(player => isRealPlayer(player))
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    readonly property real dockHeight: Config.options?.dock?.height ?? 60
    readonly property real dockMargin: Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut
    property real popupRounding: Appearance.inirEverywhere ? Appearance.inir.roundingLarge : Appearance.rounding.large
    property list<real> visualizerPoints: []

    property bool hasPlasmaIntegration: false
    Process {
        id: plasmaIntegrationAvailabilityCheckProc
        running: true
        command: ["which", "plasma-browser-integration-host"]
        onExited: (exitCode, exitStatus) => {
            root.hasPlasmaIntegration = (exitCode === 0);
        }
    }
    function isRealPlayer(player) {
        if (!(Config.options?.media?.filterDuplicatePlayers ?? true)) {
            return true;
        }
        return (
            // Remove unecessary native buses from browsers if there's plasma integration
            !(hasPlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) && !(hasPlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            // playerctld just copies other buses and we don't need duplicates
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            // Non-instance mpd bus
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd')));
    }
    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            // Find duplicates by trackTitle prefix
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            // Pick the one with non-empty trackArtUrl, or fallback to the first
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                // Parse `;`-separated values into the visualizerPoints array
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen || closingTimer.running

        Timer {
            id: closingTimer
            interval: Appearance.animationsEnabled ? 350 : 0
        }

        Connections {
            target: GlobalStates
            function onMediaControlsOpenChanged() {
                if (!GlobalStates.mediaControlsOpen) {
                    closingTimer.restart()
                } else {
                    closingTimer.stop()
                }
            }
        }

        sourceComponent: PanelWindow {
            id: mediaControlsRoot
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.mediaControlsOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Click outside to close - covers entire screen
            FocusScope {
                id: inputScope
                anchors.fill: parent
                focus: true

                Component.onCompleted: focusTimer.start()

                Timer {
                    id: focusTimer
                    interval: 100
                    repeat: false
                    onTriggered: {
                        console.log("MediaControls: Forcing focus")
                        inputScope.forceActiveFocus()
                    }
                }

                Keys.onSpacePressed: {
                    console.log("MediaControls: Space pressed")
                    if (root.activePlayer?.canTogglePlaying) {
                        root.activePlayer.togglePlaying();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.mediaControlsOpen = false
                }

                Item {
                    id: cardArea
                    width: root.widgetWidth
                height: playerColumnLayout.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Use screen height for reliable off-screen position
                readonly property real screenH: mediaControlsRoot.screen?.height ?? 1080
                readonly property real targetY: screenH - height - root.dockHeight - root.dockMargin - 5
                
                y: screenH + 50
                opacity: 0
                scale: 0.9
                transformOrigin: Item.Bottom

                states: State {
                    name: "visible"
                    when: GlobalStates.mediaControlsOpen
                    PropertyChanges {
                        target: cardArea
                        y: cardArea.targetY
                        opacity: 1
                        scale: 1
                    }
                }

                transitions: Transition {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { properties: "y,opacity,scale"; duration: 350; easing.type: Easing.OutQuint }
                }

                ColumnLayout {
                    id: playerColumnLayout
                    anchors.fill: parent
                    spacing: 8

                    Repeater {
                        model: ScriptModel {
                            values: root.meaningfulPlayers
                        }
                        delegate: PlayerControl {
                            required property MprisPlayer modelData
                            required property int index
                            player: modelData
                            visualizerPoints: root.visualizerPoints
                            implicitWidth: root.widgetWidth
                            implicitHeight: root.widgetHeight
                            radius: root.popupRounding
                            // Screen position for aurora glass
                            screenX: cardArea.x + (mediaControlsRoot.width - cardArea.width) / 2
                            screenY: cardArea.y + index * (root.widgetHeight - Appearance.sizes.elevationMargin)
                        }
                    }

                    Item { // No player placeholder
                        Layout.fillWidth: true
                        visible: root.meaningfulPlayers.length === 0
                        implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                        implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                        StyledRectangularShadow {
                            target: placeholderBackground
                            visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
                        }

                        Rectangle {
                            id: placeholderBackground
                            anchors.centerIn: parent
                            color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                                 : Appearance.auroraEverywhere ? Appearance.aurora.colPopupSurface
                                 : Appearance.colors.colLayer0
                            radius: Appearance.inirEverywhere ? Appearance.inir.roundingLarge : root.popupRounding
                            border.width: Appearance.inirEverywhere || Appearance.auroraEverywhere ? 1 : 0
                            border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder 
                                        : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder
                                        : "transparent"
                            property real padding: 20
                            implicitWidth: placeholderLayout.implicitWidth + padding * 2
                            implicitHeight: placeholderLayout.implicitHeight + padding * 2

                            ColumnLayout {
                                id: placeholderLayout
                                anchors.centerIn: parent

                                StyledText {
                                    text: Translation.tr("No active player")
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    color: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer0
                                }
                                StyledText {
                                    color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
                                    text: Translation.tr("Make sure your player has MPRIS support\\nor try turning off duplicate player filtering")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            if (GlobalStates.mediaControlsOpen)
                Notifications.timeoutAll();
        }

        function close(): void {
            GlobalStates.mediaControlsOpen = false;
        }

        function open(): void {
            GlobalStates.mediaControlsOpen = true;
            Notifications.timeoutAll();
        }
    }
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: Item {
            GlobalShortcut {
                name: "mediaControlsToggle"
                description: "Toggles media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                }
            }
            GlobalShortcut {
                name: "mediaControlsOpen"
                description: "Opens media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = true;
                }
            }
            GlobalShortcut {
                name: "mediaControlsClose"
                description: "Closes media controls on press"

                onPressed: {
                    GlobalStates.mediaControlsOpen = false;
                }
            }
            GlobalShortcut {
                name: "mediaControlsPlayPause"
                description: "Toggles play/pause when media controls are open"

                onPressed: {
                    if (GlobalStates.mediaControlsOpen && activePlayer?.canTogglePlaying) {
                        activePlayer.togglePlaying();
                    }
                }
            }
        }
    }
}
