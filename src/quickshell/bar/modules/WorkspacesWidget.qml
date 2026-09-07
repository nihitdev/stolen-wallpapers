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
    id: workspacesWidgetRoot

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

    property real targetX: 0
    x: targetX
    Behavior on x {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    height: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    y: barWindow ? barWindow.baseOffsetY + (barWindow.barHeight - height) / 2 : 0
    clip: true

    property real targetWidth: (moduleActive && workspaceCount > 0) ? wsLayout.implicitWidth + barWindow.s(isCompact ? 18 : 22) : 0
    width: targetWidth
    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    opacity: (moduleActive && workspaceCount > 0) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    property real wheelAccumulator: 0
    Timer {
        id: wsWheelTimer
        interval: 200
        onTriggered: workspacesWidgetRoot.wheelAccumulator = 0
    }

    MouseArea {
        id: wsScrollArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            wsWheelTimer.restart();
            workspacesWidgetRoot.wheelAccumulator += wheel.angleDelta.y;
            const threshold = 120;
            if (Math.abs(workspacesWidgetRoot.wheelAccumulator) >= threshold) {
                let steps = Math.trunc(workspacesWidgetRoot.wheelAccumulator / threshold);
                workspacesWidgetRoot.wheelAccumulator = workspacesWidgetRoot.wheelAccumulator % threshold;

                if (workspacesWidgetRoot.workspaceCount > 1) {
                    let cur = workspacesWidgetRoot.activeIndex;
                    let nextIndex = 0;
                    if (cur < 0) {
                        nextIndex = steps > 0 ? (workspacesWidgetRoot.workspaceCount - 1) : 0;
                    } else {
                        if (steps > 0) {
                            nextIndex = (cur - 1 + workspacesWidgetRoot.workspaceCount) % workspacesWidgetRoot.workspaceCount;
                        } else if (steps < 0) {
                            nextIndex = (cur + 1) % workspacesWidgetRoot.workspaceCount;
                        }
                    }
                    if (nextIndex !== workspacesWidgetRoot.activeIndex) {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + (nextIndex + 1) + " })");

                    }
                }
            }
        }
    }

    Rectangle {
        id: activeHighlight
        z: 3
        radius: barWindow.s(workspacesWidgetRoot.isCompact ? 7 : 8)
        color: workspacesWidgetRoot.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.05) : ThemeBackend.mauve

        property int prevIdx: 0
        property int curIdx: workspacesWidgetRoot.activeIndex

        onCurIdxChanged: {
            if (curIdx >= 0 && prevIdx >= 0) {
                if (curIdx > prevIdx) {
                    leftAnim.duration = 400;
                    rightAnim.duration = 300;
                } else if (curIdx < prevIdx) {
                    leftAnim.duration = 300;
                    rightAnim.duration = 400;
                }
            }
            if (curIdx >= 0) {
                prevIdx = curIdx;
            }
        }

        function getX(index, activeIndex) {
            if (index < 0) return 0;
            let xPos = 0;
            let spacing = barWindow.s(workspacesWidgetRoot.isCompact ? 7 : 8);
            let activeW = barWindow.s(workspacesWidgetRoot.isCompact ? 34 : 36);
            let inactiveW = barWindow.s(workspacesWidgetRoot.isCompact ? 16 : 18);
            for (let i = 0; i < index; i++) {
                xPos += (i === activeIndex ? activeW : inactiveW) + spacing;
            }
            return xPos;
        }

        property real targetLeft: curIdx >= 0 ? getX(curIdx, curIdx) : 0
        property real targetRight: curIdx >= 0 ? targetLeft + barWindow.s(workspacesWidgetRoot.isCompact ? 34 : 36) : 0
        property real actualLeft: targetLeft
        property real actualRight: targetRight

        Behavior on actualLeft { NumberAnimation { id: leftAnim; duration: 380; easing.type: Easing.OutQuint } }
        Behavior on actualRight { NumberAnimation { id: rightAnim; duration: 380; easing.type: Easing.OutQuint } }

        x: wsLayout.x + actualLeft
        y: wsLayout.y + (wsLayout.height - height) / 2
        width: actualRight - actualLeft
        height: barWindow.s(workspacesWidgetRoot.isCompact ? 16 : 18)
        opacity: (workspacesWidgetRoot.workspaceCount > 0 && workspacesWidgetRoot.activeIndex >= 0) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Row {
        id: wsLayout
        z: 2
        anchors.centerIn: parent
        spacing: barWindow.s(workspacesWidgetRoot.isCompact ? 7 : 8)

        Repeater {
            model: workspacesWidgetRoot.workspaceCount

            delegate: Item {
                id: wsPill

                required property int index
                property int wsId: index + 1
                property var ws: workspacesWidgetRoot.wsForId(wsId)
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
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsPill.wsId + " })");

                    }
                }
            }
        }
    }
}
