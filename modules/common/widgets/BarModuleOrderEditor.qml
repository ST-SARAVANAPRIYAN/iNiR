import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

/**
 * Drag-and-drop per-zone bar layout editor.
 *
 * Five zones (left, centerLeft, center, centerRight, right) each render their
 * module rows in a DropArea. Rows are draggable across zones; uniform row height
 * makes the insert-index a simple `round(y / pitch)`. The dragged row reparents
 * into `dragLayer` (top z) and follows the cursor; a primary-coloured bar marks
 * the drop slot. Writes go through Config per-leaf (never assign a whole object
 * to the bar.layout JsonObject). The pivot module (workspaces in `center`) is
 * not draggable. Modules not in any zone appear in an "Available" tray.
 */
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 10

    readonly property int rowH: 36
    readonly property int rowGap: 4
    readonly property real pitch: rowH + rowGap

    // ─── Defaults / metadata ────────────────────────────────────────────
    readonly property var _defaultLayout: ({
        left: ["leftSidebarButton", "activeWindow"],
        centerLeft: ["resources", "media"],
        center: ["workspaces"],
        centerRight: ["clock", "utilButtons", "battery"],
        right: ["rightSidebarButton", "tray", "timer", "shellUpdate", "spacer", "weather"],
    })
    readonly property var _knownIds: [
        "leftSidebarButton", "activeWindow", "resources", "media", "workspaces",
        "clock", "utilButtons", "battery", "rightSidebarButton", "tray", "timer", "shellUpdate", "spacer", "weather"
    ]
    readonly property var _zones: ["left", "centerLeft", "center", "centerRight", "right"]
    readonly property var _visKeys: ({
        leftSidebarButton: "leftSidebarButton", activeWindow: "activeWindow",
        resources: "resources", media: "media", workspaces: "workspaces", clock: "clock",
        utilButtons: "utilButtons", battery: "battery", rightSidebarButton: "rightSidebarButton",
        tray: "sysTray", weather: "weather",
    })

    function _metaIcon(id) {
        return ({ leftSidebarButton: "side_navigation", activeWindow: "window",
            resources: "memory", media: "music_note", workspaces: "workspaces", clock: "schedule",
            utilButtons: "build", battery: "battery_full", rightSidebarButton: "call_to_action",
            tray: "shelf_auto_hide", timer: "timer", shellUpdate: "system_update", spacer: "space_bar",
            weather: "cloud" })[id] || "widgets"
    }
    function _metaLabel(id) {
        return ({ leftSidebarButton: Translation.tr("Left sidebar"), activeWindow: Translation.tr("Active window"),
            resources: Translation.tr("Resources"), media: Translation.tr("Media"),
            workspaces: Translation.tr("Workspaces"), clock: Translation.tr("Clock"), utilButtons: Translation.tr("Utility buttons"),
            battery: Translation.tr("Battery"), rightSidebarButton: Translation.tr("Right sidebar"), tray: Translation.tr("System tray"),
            timer: Translation.tr("Timer"), shellUpdate: Translation.tr("Shell update"), spacer: Translation.tr("Flexible spacer"),
            weather: Translation.tr("Weather") })[id] || id
    }
    function _zoneLabel(z) {
        return ({ left: Translation.tr("Left edge"), centerLeft: Translation.tr("Center left"),
            center: Translation.tr("Center (pivot)"), centerRight: Translation.tr("Center right"),
            right: Translation.tr("Right edge") })[z] || z
    }
    function _zoneIcon(z) {
        return ({ left: "first_page", centerLeft: "align_horizontal_left", center: "align_horizontal_center",
            centerRight: "align_horizontal_right", right: "last_page" })[z] || "widgets"
    }

    // ─── Reactive layout view ───────────────────────────────────────────
    readonly property bool migrated: Config.options?.bar?.layout?.migrated === true
    function _getZone(name) {
        if (!root.migrated) return root._defaultLayout[name] ?? []
        const a = Config.options?.bar?.layout?.[name]
        return (a && a.length >= 0) ? a : (root._defaultLayout[name] ?? [])
    }
    function _placed() {
        let s = []
        for (let i = 0; i < root._zones.length; i++) s = s.concat(root._getZone(root._zones[i]))
        return s
    }
    function _available() {
        const placed = root._placed()
        // `spacer` is a reusable filler — always offered, can appear any number
        // of times in any zone.
        return root._knownIds.filter(id => id === "spacer" || placed.indexOf(id) === -1)
    }

    // ─── Mutators (per-leaf only) ───────────────────────────────────────
    function _ensureMigrated() {
        if (root.migrated) return
        const d = root._defaultLayout
        Config.setNestedValues({
            "bar.layout.left": d.left, "bar.layout.centerLeft": d.centerLeft, "bar.layout.center": d.center,
            "bar.layout.centerRight": d.centerRight, "bar.layout.right": d.right, "bar.layout.migrated": true })
    }
    function _resetToDefaults() {
        const d = root._defaultLayout
        Config.setNestedValues({
            "bar.layout.left": d.left, "bar.layout.centerLeft": d.centerLeft, "bar.layout.center": d.center,
            "bar.layout.centerRight": d.centerRight, "bar.layout.right": d.right, "bar.layout.migrated": true })
    }
    function _addToZone(id, toZone) {
        root._ensureMigrated()
        const dst = root._getZone(toZone).slice()
        if (id !== "spacer" && dst.indexOf(id) !== -1) return
        dst.push(id)
        Config.setNestedValue("bar.layout." + toZone, dst)
    }
    function _remove(zone, idx) {
        root._ensureMigrated()
        const arr = root._getZone(zone).slice()
        arr.splice(idx, 1)
        Config.setNestedValue("bar.layout." + zone, arr)
    }
    // Move from (srcZone, srcIdx) to dstZone at dstIdx. Handles same- and
    // cross-zone with a single atomic write per affected zone.
    function _dropMove(srcZone, srcIdx, dstZone, dstIdx) {
        root._ensureMigrated()
        if (srcZone === dstZone) {
            const arr = root._getZone(srcZone).slice()
            const [m] = arr.splice(srcIdx, 1)
            if (dstIdx > srcIdx) dstIdx--
            arr.splice(Math.max(0, Math.min(dstIdx, arr.length)), 0, m)
            Config.setNestedValue("bar.layout." + srcZone, arr)
        } else {
            const src = root._getZone(srcZone).slice()
            const dst = root._getZone(dstZone).slice()
            const [m] = src.splice(srcIdx, 1)
            dst.splice(Math.max(0, Math.min(dstIdx, dst.length)), 0, m)
            let u = {}
            u["bar.layout." + srcZone] = src
            u["bar.layout." + dstZone] = dst
            Config.setNestedValues(u)
        }
    }

    // ─── Drag state ─────────────────────────────────────────────────────
    property var dragInfo: null      // { zone, index, id } of the row being dragged
    property string dropZone: ""     // zone currently hovered
    property int dropIndex: -1       // insert slot in dropZone
    readonly property bool dragging: dragInfo !== null
    function _indexFromY(y, count) { return Math.max(0, Math.min(Math.round(y / root.pitch), count)) }
    function _commitDrop(dstZone) {
        if (root.dragInfo && root.dropIndex >= 0)
            root._dropMove(root.dragInfo.zone, root.dragInfo.index, dstZone, root.dropIndex)
        root._endDrag()
    }
    function _endDrag() { root.dragInfo = null; root.dropZone = ""; root.dropIndex = -1 }

    // Floating layer the dragged row reparents into so it can follow the cursor
    // above every zone. Sits in a sibling overlay (not the layout flow) so its
    // anchors don't fight the ColumnLayout.
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 0
        z: 100
        clip: false
        Item { id: dragLayer; width: root.width; height: root.height }
    }

    // ─── Header ─────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Drag modules to reorder or move them between zones. Workspaces stays the centred pivot.")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            wrapMode: Text.WordWrap
        }
        RippleButton {
            implicitWidth: 28; implicitHeight: 28
            buttonRadius: Appearance.rounding.full
            onClicked: root._resetToDefaults()
            contentItem: MaterialSymbol { anchors.centerIn: parent; text: "restart_alt"; iconSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }
            StyledToolTip { text: Translation.tr("Reset bar layout to defaults") }
        }
    }

    // ─── Draggable row (reused) ─────────────────────────────────────────
    component ModuleRow: Rectangle {
        id: rowRoot
        property string moduleId: ""
        property string zone: ""
        property int rowIndex: -1
        property bool pivot: false
        property string visibilityKey: root._visKeys[moduleId] || ""
        readonly property bool beingDragged: root.dragInfo && root.dragInfo.id === moduleId && root.dragInfo.zone === zone && root.dragInfo.index === rowIndex

        width: parent ? parent.width : implicitWidth
        height: root.rowH
        radius: Appearance.rounding.small
        color: pivot ? Appearance.colors.colSecondaryContainer
            : (dragMa.containsMouse || beingDragged ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1)
        border.color: beingDragged ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
        border.width: pivot ? 0 : 1
        opacity: beingDragged ? 0.92 : 1
        scale: beingDragged ? 1.02 : 1
        Behavior on scale { enabled: Appearance.animationsEnabled; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on color { enabled: Appearance.animationsEnabled; ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }

        readonly property color _fg: pivot ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
        readonly property color _fgSubtle: pivot ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext

        // Drag plumbing — reparent into dragLayer while dragging so the row can
        // travel over other zones; Drag.drop() fires the hovered DropArea.
        Drag.active: dragMa.drag.active
        Drag.source: rowRoot
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        states: State {
            when: dragMa.drag.active
            ParentChange { target: rowRoot; parent: dragLayer }
            PropertyChanges { rowRoot { z: 200 } }
        }

        MouseArea {
            id: dragMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: !rowRoot.pivot
            cursorShape: rowRoot.pivot ? Qt.ArrowCursor : (drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            drag.target: rowRoot
            drag.axis: Drag.XAndYAxis
            onPressed: root.dragInfo = { zone: rowRoot.zone, index: rowRoot.rowIndex, id: rowRoot.moduleId }
            onReleased: {
                if (rowRoot.Drag.target) rowRoot.Drag.drop()
                else root._endDrag()
            }
            onCanceled: root._endDrag()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 6
            spacing: 8
            MaterialSymbol {
                visible: !rowRoot.pivot
                text: "drag_indicator"
                iconSize: Appearance.font.pixelSize.normal
                color: rowRoot._fgSubtle
            }
            MaterialSymbol { text: root._metaIcon(rowRoot.moduleId); iconSize: Appearance.font.pixelSize.normal; color: rowRoot._fg }
            StyledText {
                Layout.fillWidth: true
                text: root._metaLabel(rowRoot.moduleId)
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: rowRoot._fg
                elide: Text.ElideRight
            }
            // Visibility toggle (modules that have a bar.modules.<key> switch)
            RippleButton {
                visible: !rowRoot.pivot && rowRoot.visibilityKey.length > 0
                implicitWidth: 26; implicitHeight: 26
                buttonRadius: Appearance.rounding.full
                onClicked: {
                    const k = rowRoot.visibilityKey
                    Config.setNestedValue("bar.modules." + k, !(Config.options?.bar?.modules?.[k] ?? true))
                }
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: (Config.options?.bar?.modules?.[rowRoot.visibilityKey] ?? true) ? "visibility" : "visibility_off"
                    iconSize: Appearance.font.pixelSize.small
                    color: (Config.options?.bar?.modules?.[rowRoot.visibilityKey] ?? true) ? rowRoot._fg : rowRoot._fgSubtle
                }
                StyledToolTip {
                    text: (Config.options?.bar?.modules?.[rowRoot.visibilityKey] ?? true)
                        ? Translation.tr("Hide from bar (keep in layout)") : Translation.tr("Show in bar")
                }
            }
            // Remove from layout
            RippleButton {
                visible: !rowRoot.pivot
                implicitWidth: 26; implicitHeight: 26
                buttonRadius: Appearance.rounding.full
                onClicked: root._remove(rowRoot.zone, rowRoot.rowIndex)
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "remove_circle_outline"; iconSize: Appearance.font.pixelSize.small; color: rowRoot._fgSubtle }
                StyledToolTip { text: Translation.tr("Remove from layout") }
            }
        }
    }

    // ─── Zones ──────────────────────────────────────────────────────────
    Repeater {
        model: root._zones
        delegate: ColumnLayout {
            id: zoneSection
            required property string modelData
            required property int index
            readonly property string zoneName: modelData
            readonly property var zoneItems: root._getZone(zoneName)
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                MaterialSymbol { text: root._zoneIcon(zoneSection.zoneName); iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colPrimary }
                StyledText {
                    Layout.fillWidth: true
                    text: root._zoneLabel(zoneSection.zoneName)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText { text: zoneSection.zoneItems.length + ""; font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
            }

            DropArea {
                id: zoneDrop
                Layout.fillWidth: true
                implicitHeight: Math.max(rowCol.implicitHeight, root.rowH)
                readonly property string zoneName: zoneSection.zoneName
                onPositionChanged: drag => { root.dropZone = zoneName; root.dropIndex = root._indexFromY(drag.y, zoneSection.zoneItems.length) }
                onExited: if (root.dropZone === zoneName) { root.dropZone = ""; root.dropIndex = -1 }
                onDropped: root._commitDrop(zoneName)

                Rectangle {
                    visible: zoneSection.zoneItems.length === 0
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: "transparent"
                    border.color: (root.dragging && root.dropZone === zoneSection.zoneName) ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    border.width: 1
                    StyledText { anchors.centerIn: parent; text: Translation.tr("Drop here"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colSubtext }
                }

                Column {
                    id: rowCol
                    width: parent.width
                    spacing: root.rowGap
                    Repeater {
                        model: zoneSection.zoneItems
                        delegate: ModuleRow {
                            required property string modelData
                            required property int index
                            moduleId: modelData
                            zone: zoneSection.zoneName
                            rowIndex: index
                            pivot: zoneSection.zoneName === "center" && modelData === "workspaces"
                        }
                    }
                }

                // Drop slot indicator
                Rectangle {
                    visible: root.dragging && root.dropZone === zoneSection.zoneName && root.dropIndex >= 0 && zoneSection.zoneItems.length > 0
                    width: parent.width
                    height: 3
                    radius: 1.5
                    color: Appearance.colors.colPrimary
                    y: Math.min(root.dropIndex, zoneSection.zoneItems.length) * root.pitch - root.rowGap / 2 - height / 2
                    z: 50
                }
            }

            Rectangle {
                visible: zoneSection.index < root._zones.length - 1
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }
        }
    }

    // ─── Available (unplaced) modules ───────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4
        visible: root._available().length > 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            MaterialSymbol { text: "add_box"; iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colPrimary }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Available modules")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
            }
        }
        Repeater {
            model: root._available()
            delegate: Rectangle {
                id: availRow
                required property string modelData
                readonly property string moduleId: modelData
                Layout.fillWidth: true
                implicitHeight: root.rowH
                radius: Appearance.rounding.small
                color: "transparent"
                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 4
                    spacing: 8
                    MaterialSymbol { text: root._metaIcon(availRow.moduleId); iconSize: Appearance.font.pixelSize.normal; color: Appearance.colors.colSubtext }
                    StyledText {
                        Layout.fillWidth: true
                        text: root._metaLabel(availRow.moduleId)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                    Repeater {
                        model: root._zones
                        delegate: RippleButton {
                            required property string modelData
                            readonly property string targetZone: modelData
                            implicitWidth: 26; implicitHeight: 26
                            buttonRadius: Appearance.rounding.full
                            onClicked: root._addToZone(availRow.moduleId, targetZone)
                            contentItem: MaterialSymbol { anchors.centerIn: parent; text: root._zoneIcon(parent.targetZone); iconSize: Appearance.font.pixelSize.small; color: Appearance.colors.colOnLayer1 }
                            StyledToolTip { text: Translation.tr("Add to ") + root._zoneLabel(parent.targetZone) }
                        }
                    }
                }
            }
        }
    }
}
