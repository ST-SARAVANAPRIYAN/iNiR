import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// ============================================================================
// BATTERY CONSERVATION MODE BAR MODULE
// ============================================================================

MouseArea {
    id: root
    
    // --- Properties ---
    property bool compact: false
    property bool showLabel: true
    property real iconSize: Appearance.font.pixelSize.large
    
    // --- State Mapping ---
    enabled: BatteryConservation.functional
    visible: BatteryConservation.available
    hoverEnabled: true

    opacity: BatteryConservation.functional ? 1.0 : 0.5

    // --- Dynamic Sizing ---
    implicitHeight: Appearance.sizes.barHeight
    implicitWidth: (visible && (Config.options?.bar?.modules?.lenovoConservation ?? true)) 
        ? (contentLayout.implicitWidth + 20) 
        : 0

    // --- Action ---
    onClicked: if (BatteryConservation.functional) BatteryConservation.toggle()

    // --- Layout ---
    RowLayout {
        id: contentLayout
        spacing: 8
        anchors.centerIn: parent
        visible: root.implicitWidth > 0

        MaterialSymbol {
            id: symbol
            text: !BatteryConservation.functional ? "error" : (BatteryConservation.isActive ? "shield_with_heart" : "shield")
            iconSize: root.iconSize
            fill: BatteryConservation.isActive ? 1 : 0
            
            color: !BatteryConservation.functional 
                ? Appearance.colors.colError
                : (BatteryConservation.isActive 
                    ? (Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary)
                    : (Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer2))
            
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        StyledText {
            visible: !root.compact && root.showLabel
            text: !BatteryConservation.functional ? Translation.tr("Missing") : (BatteryConservation.isActive ? Translation.tr("Conserve") : Translation.tr("Standard"))
            font.bold: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: !BatteryConservation.functional 
                ? Appearance.colors.colError
                : (BatteryConservation.isActive 
                    ? (Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary)
                    : (Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer2))
        }
    }

    // --- Native Ripple Effect ---
    RippleButton {
        id: rippleProvider
        anchors.fill: parent
        colBackground: "transparent"
        colBackgroundHover: "transparent"
        rippleEnabled: true
        onClicked: BatteryConservation.toggle()
        buttonRadius: Appearance.rounding.small
        visible: root.implicitWidth > 0
    }

    // --- Popup ---
    BatteryConservationPopup {
        id: batteryConservationPopup
        hoverTarget: root
    }

    // --- Loading State ---
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Qt.rgba(0,0,0,0.4)
        visible: BatteryConservation.loading && root.implicitWidth > 0

        MaterialLoadingIndicator {
            anchors.centerIn: parent
            width: parent.height * 0.5
            height: width
        }
    }
}
