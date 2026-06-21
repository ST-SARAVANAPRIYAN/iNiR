pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    property bool ready: true

    Connections {
        target: Battery
        function onIsPluggedInChanged() {
            const isPlugged = !Battery.available || Battery.isPluggedIn;
            const scriptPath = Quickshell.shellPath("scripts/niri-config.py");
            Quickshell.execDetached(["python3", scriptPath, "sync-power-state", String(isPlugged)]);
        }
    }

    Component.onCompleted: {
        const isPlugged = !Battery.available || Battery.isPluggedIn;
        const scriptPath = Quickshell.shellPath("scripts/niri-config.py");
        Quickshell.execDetached(["python3", scriptPath, "sync-power-state", String(isPlugged)]);
    }
}
