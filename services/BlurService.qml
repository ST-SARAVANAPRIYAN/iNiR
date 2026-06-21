pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property string filePath: FileUtils.trimFileProtocol(Directories.home + "/.config/bluri/settings.json")
    property alias options: blurOptionsJsonAdapter
    property bool ready: false
    property bool lastRefreshRateEfficiencyState: false

    property var _cmdQueue: []
    property bool _running: false

    function _runNext() {
        if (root._running || root._cmdQueue.length === 0) return;
        root._running = true;
        const cmd = root._cmdQueue.shift();
        syncProcess.command = cmd;
        syncProcess.running = true;
    }

    Process {
        id: syncProcess
        stdout: StdioCollector { id: syncOut }
        stderr: StdioCollector { id: syncErr }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("[BlurService] syncProcess failed:", syncErr.text || syncOut.text);
            }
            root._running = false;
            root._runNext();
        }
    }

    function runCommand(args) {
        const scriptPath = Quickshell.shellPath("scripts/niri-config.py");
        const fullCmd = ["python3", scriptPath].concat(args);

        // Filter out any pending commands of the same type in the queue
        if (args[0] === "set-blur-rules") {
            root._cmdQueue = root._cmdQueue.filter(cmd => cmd[2] !== "set-blur-rules");
        } else if (args[0] === "sync-refresh-rate") {
            root._cmdQueue = root._cmdQueue.filter(cmd => cmd[2] !== "sync-refresh-rate");
        }

        root._cmdQueue.push(fullCmd);
        root._runNext();
    }

    function queueSync() {
        syncDebounceTimer.restart();
    }

    function triggerSync() {
        if (!root.ready) return;

        const scriptPath = Quickshell.shellPath("scripts/niri-config.py");
        const isPlugged = !Battery.available || Battery.isPluggedIn;

        const effectiveBlurEnabled = root.options.mode === "on"
            ? root.options.blur_enabled
            : root.options.mode === "auto"
                ? (isPlugged && root.options.blur_enabled)
                : false;

        const payload = {
            mode: root.options.mode,
            blur_enabled: effectiveBlurEnabled,
            active_opacity: root.options.active_opacity,
            inactive_opacity: root.options.inactive_opacity,
            xray: root.options.xray,
            refresh_rate_efficiency: root.options.refresh_rate_efficiency,
            passes: root.options.passes,
            offset: root.options.offset,
            noise: root.options.noise,
            saturation: root.options.saturation,
            window_rules_enabled: root.options.window_rules_enabled,
            window_matcher: root.options.window_matcher,
            layer_rules_enabled: root.options.layer_rules_enabled,
            layer_namespace: root.options.layer_namespace,
            layer_opacity: root.options.layer_opacity
        };

        console.log("[BlurService] Syncing blur payload to Niri config:", JSON.stringify(payload));
        root.runCommand(["set-blur-rules", JSON.stringify(payload)]);

        // Sync refresh rate if efficiency mode is active, or if it was just turned off!
        const efficiencyActive = root.options.refresh_rate_efficiency;
        if (efficiencyActive || root.lastRefreshRateEfficiencyState !== efficiencyActive) {
            const targetPlugged = efficiencyActive ? isPlugged : true;
            console.log("[BlurService] Syncing refresh rate: targetPlugged=" + targetPlugged);
            root.runCommand(["sync-refresh-rate", String(targetPlugged)]);
            root.lastRefreshRateEfficiencyState = efficiencyActive;
        }
    }

    FileView {
        id: blurFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: {
            fileWriteTimer.restart()
        }
        onLoaded: {
            root.ready = true
            root.queueSync()
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                console.log("[BlurService] File not found, creating new file.")
                const parentDir = root.filePath.substring(0, root.filePath.lastIndexOf('/'))
                Process.exec(["/usr/bin/mkdir", "-p", parentDir])
                blurFileView.writeAdapter()
            }
            root.ready = true
            root.queueSync()
        }

        JsonAdapter {
            id: blurOptionsJsonAdapter
            property string mode: "auto"
            property real active_opacity: 0.95
            property real inactive_opacity: 0.70
            property bool blur_enabled: true
            property bool xray: true
            property int passes: 3
            property real offset: 3.0
            property real noise: 0.02
            property real saturation: 1.5
            property bool window_rules_enabled: true
            property string window_matcher: "^(Alacritty|Foot|foot|kitty|org\\.wezfurlong\\.wezterm|com\\.mitchellh\\.ghostty)$"
            property bool layer_rules_enabled: true
            property string layer_namespace: "^(launcher|waybar|walker|fuzzel|wofi)$"
            property real layer_opacity: 0.85
            property bool refresh_rate_efficiency: false

            onModeChanged: root.queueSync()
            onActive_opacityChanged: root.queueSync()
            onInactive_opacityChanged: root.queueSync()
            onBlur_enabledChanged: root.queueSync()
            onXrayChanged: root.queueSync()
            onPassesChanged: root.queueSync()
            onOffsetChanged: root.queueSync()
            onNoiseChanged: root.queueSync()
            onSaturationChanged: root.queueSync()
            onWindow_rules_enabledChanged: root.queueSync()
            onWindow_matcherChanged: root.queueSync()
            onLayer_rules_enabledChanged: root.queueSync()
            onLayer_namespaceChanged: root.queueSync()
            onLayer_opacityChanged: root.queueSync()
            onRefresh_rate_efficiencyChanged: root.queueSync()
        }
    }

    Timer {
        id: fileReloadTimer
        interval: 50
        repeat: false
        onTriggered: blurFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: 50
        repeat: false
        onTriggered: blurFileView.writeAdapter()
    }

    Timer {
        id: syncDebounceTimer
        interval: 200
        repeat: false
        onTriggered: root.triggerSync()
    }

    // Monitor Battery.isPluggedIn so that if mode is "auto" or refresh_rate_efficiency is enabled, we trigger sync
    // immediately when power status changes (plugged in / unplugged)!
    Connections {
        target: Battery
        function onIsPluggedInChanged() {
            if (root.options.mode === "auto" || root.options.refresh_rate_efficiency) {
                root.queueSync();
            }
        }
    }
}
