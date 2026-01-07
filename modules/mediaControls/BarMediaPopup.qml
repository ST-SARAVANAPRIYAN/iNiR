pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.services
import "root:"

Item {
    id: root
    signal closeRequested()

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: Mpris.players.values.filter(player => isRealPlayer(player))
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.normal
    property list<real> visualizerPoints: []

    property bool hasPlasmaIntegration: false
    Process {
        id: plasmaIntegrationAvailabilityCheckProc
        running: true
        command: ["/usr/bin/bash", "-c", "command -v plasma-browser-integration-host"]
        onExited: (exitCode, exitStatus) => {
            root.hasPlasmaIntegration = (exitCode === 0);
        }
    }

    function isRealPlayer(player) {
        if (!(Config.options?.media?.filterDuplicatePlayers ?? true)) {
            return true;
        }
        return (
            !(hasPlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.firefox')) &&
            !(hasPlasmaIntegration && player.dbusName.startsWith('org.mpris.MediaPlayer2.chromium')) &&
            !player.dbusName?.startsWith('org.mpris.MediaPlayer2.playerctld') &&
            !(player.dbusName?.endsWith('.mpd') && !player.dbusName.endsWith('MediaPlayer2.mpd'))
        );
    }

    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();
        for (let i = 0; i < players.length; ++i) {
            if (used.has(i)) continue;
            let p1 = players[i];
            let group = [i];
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined) chosenIdx = group[0];
            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }

    // Cava visualizer process
    Process {
        id: cavaProc
        running: root.meaningfulPlayers.length > 0
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    implicitWidth: widgetWidth + (visualizerContainer.visible ? visualizerContainer.width : 0)
    implicitHeight: playerColumn.implicitHeight

    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: playerColumn
            Layout.fillHeight: true
            Layout.preferredWidth: root.widgetWidth
            spacing: -Appearance.sizes.elevationMargin

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
                }
            }

            // No player placeholder
            Item {
                visible: root.meaningfulPlayers.length === 0
                Layout.fillWidth: true
                implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                StyledRectangularShadow {
                    target: placeholderBackground
                }

                Rectangle {
                    id: placeholderBackground
                    anchors.centerIn: parent
                    color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                         : Appearance.auroraEverywhere ? Appearance.aurora.colPopupSurface
                         : Appearance.colors.colLayer0
                    radius: Appearance.inirEverywhere ? Appearance.inir.roundingNormal : root.popupRounding
                    border.width: Appearance.inirEverywhere || Appearance.auroraEverywhere ? 1 : 0
                    border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder
                                : Appearance.auroraEverywhere ? Appearance.aurora.colPopupBorder
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
                            color: Appearance.inirEverywhere ? Appearance.inir.colText
                                : Appearance.auroraEverywhere ? Appearance.colors.colOnLayer0
                                : Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            color: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary
                                : Appearance.auroraEverywhere ? Appearance.aurora.colTextSecondary
                                : Appearance.colors.colSubtext
                            text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                    }
                }
            }
        }

        // Contenedor del visualizador lateral
        Item {
            id: visualizerContainer
            // Ajustar ancho basado en visibilidad
            Layout.preferredWidth: 50
            Layout.fillHeight: true
            Layout.topMargin: 0
            Layout.bottomMargin: 0
            Layout.leftMargin: -12 // Solapamiento para ocultar la unión
            z: -1 // Detrás del reproductor
            
            // Mostrar solo si hay reproducción y datos
            visible: root.meaningfulPlayers.length > 0 && root.visualizerPoints.length > 0
            opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            // Fondo del visualizador (estilo unificado)
            Rectangle {
                anchors.fill: parent
                // Solo redondear esquinas derechas para que parezca que sale del reproductor
                radius: root.popupRounding
                
                // Color adaptativo según el tema
                color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
                     : Appearance.auroraEverywhere ? ColorUtils.transparentize(Appearance.colors.colLayer0, 0.6)
                     : Appearance.colors.colLayer0
                
                border.width: Appearance.inirEverywhere || Appearance.auroraEverywhere ? 1 : 0
                border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder 
                            : Appearance.auroraEverywhere ? Appearance.aurora.colTooltipBorder
                            : "transparent"

                // Sombra si no estamos en Inir/Aurora
                StyledRectangularShadow {
                    target: parent
                    visible: !Appearance.inirEverywhere && !Appearance.auroraEverywhere
                }

                // Blur para efecto Aurora/Glass
                layer.enabled: Appearance.auroraEverywhere
                layer.effect: StyledBlurEffect {
                    source: parent
                }
            }

            // El visualizador en sí
            CavaVisualizer {
                anchors.fill: parent
                anchors.margins: 6 // Margen interno para que no toque los bordes
                anchors.leftMargin: 18 // Margen izquierdo extra para compensar el solapamiento
                
                points: root.visualizerPoints
                // Menos barras pero más gruesas para este espacio vertical estrecho
                barCount: 5 
                barSpacing: 4
                barRadius: 2
                smoothing: 2
                maxVisualizerValue: 1200 // Ajuste de sensibilidad
                
                // Colores del tema
                colorLow: Appearance.inirEverywhere ? Appearance.inir.colPrimary
                        : Appearance.auroraEverywhere ? Appearance.aurora.colPrimary
                        : Appearance.colors.colPrimary
                colorMed: Appearance.inirEverywhere ? Appearance.inir.colPrimary
                        : Appearance.auroraEverywhere ? Appearance.aurora.colPrimary
                        : Appearance.colors.colPrimary
                colorHigh: Appearance.inirEverywhere ? Appearance.inir.colSecondaryContainer
                         : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface
                         : Appearance.colors.colSecondaryContainer
            }
        }
    }
}
