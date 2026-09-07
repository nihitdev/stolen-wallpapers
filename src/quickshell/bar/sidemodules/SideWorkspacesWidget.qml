import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../../reusables"
import "../../"

Rectangle {
    id: sideWsRoot

    property var barWindow
    property var paths
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)



    property int workspaceCount: (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.workspaceCount !== undefined) ? Math.max(2, Math.min(10, Config.rawSettings.bar.workspaceCount)) : ((typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.general && Config.rawSettings.general.workspaceCount !== undefined) ? Math.max(2, Math.min(10, Config.rawSettings.general.workspaceCount)) : ((typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.workspaceCount !== undefined) ? Math.max(2, Math.min(10, Config.rawSettings.workspaceCount)) : 8))

    function wsForId(id) {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null;
    }

    property int activeIndex: {
        let idx = -1;
        const fw = Hyprland.focusedWorkspace;
        if (!fw) return -1;
        idx = fw.id - 1;

        return (idx >= 0 && idx < workspaceCount) ? idx : -1;
    }

    property real targetY: 0
    y: targetY
    Behavior on y {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    property real targetWidth: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    property real targetHeight: (moduleActive && workspaceCount > 0) ? wsCol.implicitHeight + (barWindow ? barWindow.s(isCompact ? 18 : 22) : (isCompact ? 18 : 22)) : 0

    width: targetWidth
    height: targetHeight

    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    radius: ThemeBackend.borderRadius
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    border.width: 0
    clip: true

    opacity: (moduleActive && workspaceCount > 0) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property real wheelAccumulator: 0
    Timer {
        id: wsWheelTimer
        interval: 200
        onTriggered: sideWsRoot.wheelAccumulator = 0
    }

    MouseArea {
        id: wsScrollArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            wsWheelTimer.restart();
            sideWsRoot.wheelAccumulator += wheel.angleDelta.y;
            const threshold = 120;
            if (Math.abs(sideWsRoot.wheelAccumulator) >= threshold) {
                let steps = Math.trunc(sideWsRoot.wheelAccumulator / threshold);
                sideWsRoot.wheelAccumulator = sideWsRoot.wheelAccumulator % threshold;

                if (sideWsRoot.workspaceCount > 1) {
                    let cur = sideWsRoot.activeIndex;
                    let nextIndex = 0;
                    if (cur < 0) {
                        nextIndex = steps > 0 ? (sideWsRoot.workspaceCount - 1) : 0;
                    } else {
                        if (steps > 0) {
                            nextIndex = (cur - 1 + sideWsRoot.workspaceCount) % sideWsRoot.workspaceCount;
                        } else if (steps < 0) {
                            nextIndex = (cur + 1) % sideWsRoot.workspaceCount;
                        }
                    }
                    if (nextIndex !== sideWsRoot.activeIndex) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + (nextIndex + 1) + " })");

                    }
                }
            }
        }
    }

    Rectangle {
        id: activeHighlight
        z: 3
        radius: barWindow ? barWindow.s(sideWsRoot.isCompact ? 7 : 8) : (sideWsRoot.isCompact ? 7 : 8)
        color: sideWsRoot.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.05) : ThemeBackend.mauve

        property int prevIdx: 0
        property int curIdx: sideWsRoot.activeIndex

        onCurIdxChanged: {
            if (curIdx >= 0 && prevIdx >= 0) {
                if (curIdx > prevIdx) {
                    topAnim.duration = 400;
                    bottomAnim.duration = 300;
                } else if (curIdx < prevIdx) {
                    topAnim.duration = 300;
                    bottomAnim.duration = 400;
                }
            }
            if (curIdx >= 0) {
                prevIdx = curIdx;
            }
        }

        function getY(index, activeIndex) {
            if (index < 0) return 0;
            let yPos = 0;
            let spacing = barWindow ? barWindow.s(sideWsRoot.isCompact ? 7 : 8) : (sideWsRoot.isCompact ? 7 : 8);
            let activeH = barWindow ? barWindow.s(sideWsRoot.isCompact ? 34 : 36) : (sideWsRoot.isCompact ? 34 : 36);
            let inactiveH = barWindow ? barWindow.s(sideWsRoot.isCompact ? 16 : 18) : (sideWsRoot.isCompact ? 16 : 18);
            for (let i = 0; i < index; i++) {
                yPos += (i === activeIndex ? activeH : inactiveH) + spacing;
            }
            return yPos;
        }

        property real targetTop: curIdx >= 0 ? getY(curIdx, curIdx) : 0
        property real targetBottom: curIdx >= 0 ? targetTop + (barWindow ? barWindow.s(sideWsRoot.isCompact ? 34 : 36) : (sideWsRoot.isCompact ? 34 : 36)) : 0
        property real actualTop: targetTop
        property real actualBottom: targetBottom

        Behavior on actualTop { NumberAnimation { id: topAnim; duration: 380; easing.type: Easing.OutQuint } }
        Behavior on actualBottom { NumberAnimation { id: bottomAnim; duration: 380; easing.type: Easing.OutQuint } }

        x: wsCol.x + (wsCol.width - width) / 2
        y: wsCol.y + actualTop
        width: barWindow ? barWindow.s(sideWsRoot.isCompact ? 16 : 18) : (sideWsRoot.isCompact ? 16 : 18)
        height: actualBottom - actualTop
        opacity: (sideWsRoot.workspaceCount > 0 && sideWsRoot.activeIndex >= 0) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Column {
        id: wsCol
        z: 2
        anchors.centerIn: parent
        spacing: barWindow ? barWindow.s(sideWsRoot.isCompact ? 7 : 8) : (sideWsRoot.isCompact ? 7 : 8)

        Repeater {
            model: sideWsRoot.workspaceCount

            delegate: Item {
                id: wsPill

                required property int index
                property int wsId: index + 1
                property var ws: sideWsRoot.wsForId(wsId)
                property bool isOccupied: {
                    initAnimTrigger = true;

                }

                Timer {
                    id: animTimer
                    running: false; repeat: false
                    onTriggered: wsPill.initAnimTrigger = true
                }

                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: wsPillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsPill.wsId + " })");

                    }
                }
            }
        }
    }
}
