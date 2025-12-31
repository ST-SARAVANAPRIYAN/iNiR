import QtQuick
import qs.modules.common
import qs.modules.common.functions

Rectangle {
    id: root

    property bool editMode: false

    radius: Appearance.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal
    color: Appearance.inirEverywhere ? Appearance.inir.colLayer1
         : Appearance.auroraEverywhere ? "transparent" 
         : Appearance.colors.colLayer1
    border.width: Appearance.inirEverywhere ? 1 : 0
    border.color: Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"

    signal openAudioOutputDialog()
    signal openAudioInputDialog()
    signal openBluetoothDialog()
    signal openNightLightDialog()
    signal openWifiDialog()
}
