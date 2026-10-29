import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: tinker
    width: 520
    height: 550

    property var pal
    signal requestClose()

    // Live Tunable Hyprland Properties
    property int activeOp: 100
    property int inactiveOp: 92
    property int rounding: 14
    property int gapsIn: 6
    property int gapsOut: 12
    property int borderSize: 2
    property int blurSize: 6
    property int blurPasses: 2
    property bool blurOn: true
    property bool animOn: true
    property real gearAngle: 0
    property bool savedFlash: false
    property bool dirty: false

    // Retractable Nonsense-Tool Arm State!
    property real armExtend: 0.0
    property int toolIdx: 0
    readonly property var nonsenseTools: [
        { icon: "🐔", name: "RUBBER CHICKEN" },
        { icon: "🪠", name: "GAP PLUNGER" },
        { icon: "🍌", name: "SCALE BANANA" },
        { icon: "🍕", name: "BLUR CUTTER" },
        { icon: "🪄", name: "PIXEL WAND" },
        { icon: "🦆", name: "DEBUG DUCK" }
    ]

    function cycleTool() {
        armRetractAnim.restart()
    }

    SequentialAnimation {
        id: armRetractAnim
        NumberAnimation { target: tinker; property: "armExtend"; to: 0.15; duration: 140; easing.type: Easing.InBack }
        ScriptAction { script: { tinker.toolIdx = (tinker.toolIdx + 1) % tinker.nonsenseTools.length } }
        NumberAnimation { target: tinker; property: "armExtend"; to: 1.0; duration: 280; easing.type: Easing.OutBack }
    }

    Component.onCompleted: {
        hyprGetProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            toolIdx = Math.floor(Math.random() * nonsenseTools.length)
            armExtend = 0.0
            armPopOut.restart()
            if (!dirty) {
                hyprGetProc.running = false
                hyprGetProc.running = true
            }
        } else if (dirty) {
            saveToConfig()
        }
    }

    NumberAnimation {
        id: armPopOut
        target: tinker
        property: "armExtend"
        from: 0.0; to: 1.0
        duration: 650
        easing.type: Easing.OutElastic
    }

    Timer {
        id: autoSaveTimer
        interval: 300
        onTriggered: {
            if (tinker.dirty) tinker.saveToConfig()
        }
    }

    Process {
        id: hyprGetProc
        command: [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "hypr-get"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const lines = data.trim().split("\n")
                    const o = JSON.parse(lines[lines.length - 1])
                    tinker.activeOp = o.active_op
                    tinker.inactiveOp = o.inactive_op
                    tinker.rounding = o.rounding
                    tinker.gapsIn = o.gaps_in
                    tinker.gapsOut = o.gaps_out
                    tinker.borderSize = o.border_size
                    tinker.blurSize = o.blur_size
                    tinker.blurPasses = o.blur_passes
                    tinker.blurOn = o.blur_on
                    tinker.animOn = o.anim_on
                } catch (e) {}
            }
        }
    }

    function getVal(k) {
        if (k === "activeOp") return tinker.activeOp
        if (k === "inactiveOp") return tinker.inactiveOp
        if (k === "rounding") return tinker.rounding
        if (k === "gapsIn") return tinker.gapsIn
        if (k === "gapsOut") return tinker.gapsOut
        if (k === "borderSize") return tinker.borderSize
        if (k === "blurSize") return tinker.blurSize
        return 0
    }

    function setVal(k, v, minV, maxV, kw, scale) {
        const clamped = Math.max(minV, Math.min(maxV, Math.round(v)))
        if (k === "activeOp") tinker.activeOp = clamped
        else if (k === "inactiveOp") tinker.inactiveOp = clamped
        else if (k === "rounding") tinker.rounding = clamped
        else if (k === "gapsIn") tinker.gapsIn = clamped
        else if (k === "gapsOut") tinker.gapsOut = clamped
        else if (k === "borderSize") tinker.borderSize = clamped
        else if (k === "blurSize") tinker.blurSize = clamped

        const formatted = scale < 1.0 ? (clamped * scale).toFixed(2) : clamped.toString()
        tinker.gearAngle += 20
        tinker.dirty = true
        Quickshell.execDetached(["hyprctl", "keyword", kw, formatted])
        autoSaveTimer.restart()
    }

    function saveToConfig() {
        tinker.dirty = false
        tinker.gearAngle += 90
        tinker.savedFlash = true
        flashReset.restart()
        Quickshell.execDetached([
            Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh",
            "hypr-save",
            tinker.activeOp.toString(),
            tinker.inactiveOp.toString(),
            tinker.rounding.toString(),
            tinker.gapsIn.toString(),
            tinker.gapsOut.toString(),
            tinker.borderSize.toString(),
            tinker.blurSize.toString(),
            tinker.blurPasses.toString(),
            tinker.blurOn ? "1" : "0",
            tinker.animOn ? "1" : "0"
        ])
    }

    function openHyprlandLua() {
        if (tinker.dirty) saveToConfig()
        Quickshell.execDetached([Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "edit-hypr"])
        tinker.requestClose()
    }

    Timer {
        id: flashReset
        interval: 1200
        onTriggered: tinker.savedFlash = false
    }

    // 1. Retractable Scissor-Link Robot Arm Holding Nonsense Tools! (Click to Swap Tool!)
    Item {
        id: mechArm
        x: 92 - 82 * tinker.armExtend
        y: 32
        width: 110; height: 75

        // Scissor Struts (Accordion X-Links)
        Repeater {
            model: 3
            Item {
                x: 36 + index * (22 * tinker.armExtend)
                y: 22
                Rectangle {
                    width: 26; height: 4; radius: 2
                    color: tinker.pal.c8
                    rotation: 35 - 15 * tinker.armExtend
                }
                Rectangle {
                    width: 26; height: 4; radius: 2
                    color: tinker.pal.c11
                    rotation: -35 + 15 * tinker.armExtend
                }
            }
        }

        // Robot Pincer Claw + Funny Nonsense Tool Badge
        Rectangle {
            x: 0; y: 4
            width: 56; height: 54; radius: 16
            color: tinker.pal.bg
            border.color: tinker.pal.c11
            border.width: 3
            rotation: -12 + Math.sin(tinker.gearAngle * 0.08) * 14

            Column {
                anchors.centerIn: parent
                spacing: 1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tinker.nonsenseTools[tinker.toolIdx].icon
                    font.pixelSize: 24
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tinker.nonsenseTools[tinker.toolIdx].name
                    color: tinker.pal.c11
                    font.family: "Orbitron"
                    font.pixelSize: 6
                    font.bold: true
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: tinker.cycleTool()
            }
        }
    }

    // 2. Tinker's Tall Vertical Periscope / Pill Head + Giant Loupe Monocle
    Rectangle {
        width: 108; height: 92; radius: 42
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 28
        y: 12
        color: tinker.pal.bg
        border.color: tinker.pal.c11
        border.width: 3

        MouseArea { anchors.fill: parent }

        // Spinning Brass Gear Crest on Forehead
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            text: "󰒓"
            color: tinker.pal.c11
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            rotation: tinker.gearAngle
            Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
        }

        // Giant Jeweler's Loupe Monocle + Tiny Squinting Eye
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 34
            spacing: 10

            // Giant Inspector Loupe
            Rectangle {
                width: 44; height: 44; radius: 22
                color: Qt.darker(tinker.pal.bg, 1.45)
                border.color: tinker.pal.c11
                border.width: 4
                Rectangle {
                    width: 18; height: 18; radius: 9
                    anchors.centerIn: parent
                    color: tinker.pal.c12
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        x: 3; y: 3
                        color: "#ffffff"
                    }
                }
            }

            // Tiny Squinting Calibrator Eye
            Rectangle {
                width: 16; height: 6; radius: 3
                anchors.verticalCenter: parent.verticalCenter
                color: tinker.pal.c10
            }
        }
    }

    // 3. Tinker's Control Panel Belly
    Rectangle {
        width: 410
        height: 404
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 28
        y: 108
        color: tinker.pal.bg
        border.color: tinker.pal.c11
        border.width: 3

        MouseArea { anchors.fill: parent; z: -1 }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 8

            Row {
                width: parent.width
                Text {
                    width: parent.width * 0.62
                    text: "TINKER // HYPRLAND LIVE TUNER"
                    color: tinker.pal.c11
                    font.family: "Orbitron"
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    width: parent.width * 0.38
                    horizontalAlignment: Text.AlignRight
                    text: tinker.savedFlash ? "✓ AUTO-SAVED" : "CLICK ARM TO SWAP TOOL"
                    color: tinker.savedFlash ? tinker.pal.c10 : tinker.pal.c8
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Repeater {
                model: [
                    { label: "Active Opacity",   prop: "activeOp",   min: 50, max: 100, unit: "%",  col: "c11", kw: "decoration:active_opacity",   scale: 0.01 },
                    { label: "Inactive Opacity", prop: "inactiveOp", min: 40, max: 100, unit: "%",  col: "c5",  kw: "decoration:inactive_opacity", scale: 0.01 },
                    { label: "Corner Rounding",  prop: "rounding",   min: 0,  max: 30,  unit: "px", col: "c4",  kw: "decoration:rounding",         scale: 1.0  },
                    { label: "Inner Gaps",       prop: "gapsIn",     min: 0,  max: 24,  unit: "px", col: "c2",  kw: "general:gaps_in",             scale: 1.0  },
                    { label: "Outer Gaps",       prop: "gapsOut",    min: 0,  max: 40,  unit: "px", col: "c6",  kw: "general:gaps_out",            scale: 1.0  },
                    { label: "Border Width",     prop: "borderSize", min: 0,  max: 6,   unit: "px", col: "c13", kw: "general:border_size",         scale: 1.0  },
                    { label: "Blur Radius",      prop: "blurSize",   min: 1,  max: 20,  unit: "px", col: "c12", kw: "decoration:blur:size",        scale: 1.0  }
                ]

                Column {
                    id: sRow
                    width: parent.width
                    spacing: 2
                    readonly property int curVal: tinker.getVal(modelData.prop)
                    readonly property real norm: (curVal - modelData.min) / (modelData.max - modelData.min)
                    readonly property color barCol: tinker.pal[modelData.col] || tinker.pal.c11

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width * 0.65
                            text: modelData.label
                            color: tinker.pal.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            width: parent.width * 0.35
                            horizontalAlignment: Text.AlignRight
                            text: sRow.curVal + modelData.unit
                            color: sRow.barCol
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 14; radius: 7
                        color: Qt.darker(tinker.pal.bg, 1.45)
                        border.color: tinker.pal.c0; border.width: 1

                        Rectangle {
                            width: parent.width * Math.max(0.03, Math.min(1.0, sRow.norm))
                            height: parent.height; radius: 7
                            color: sRow.barCol
                            Behavior on width { NumberAnimation { duration: 35 } }
                        }

                        Rectangle {
                            width: 12; height: 18; radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(parent.width - width, parent.width * sRow.norm - width / 2))
                            color: tinker.pal.fg
                            border.color: sRow.barCol; border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            function setFromX(mx) {
                                const ratio = Math.max(0, Math.min(1, mx / width))
                                const v = modelData.min + ratio * (modelData.max - modelData.min)
                                tinker.setVal(modelData.prop, v, modelData.min, modelData.max, modelData.kw, modelData.scale)
                            }
                            onPressed: mouse => setFromX(mouse.x)
                            onPositionChanged: mouse => { if (pressed) setFromX(mouse.x) }
                            onWheel: wheel => {
                                const step = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 1 : -1
                                tinker.setVal(modelData.prop, sRow.curVal + step, modelData.min, modelData.max, modelData.kw, modelData.scale)
                            }
                        }
                    }
                }
            }

            Row {
                width: parent.width
                topPadding: 2
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) * 0.5
                    height: 30; radius: 9
                    color: tinker.blurOn ? tinker.pal.c12 : tinker.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: tinker.blurOn ? "󰂵 Glass Blur: ON" : "󰂷 Glass Blur: OFF"
                        color: tinker.blurOn ? tinker.pal.bg : tinker.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tinker.blurOn = !tinker.blurOn
                            tinker.dirty = true
                            tinker.gearAngle += 30
                            tinker.cycleTool()
                            Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", tinker.blurOn ? "true" : "false"])
                            autoSaveTimer.restart()
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) * 0.5
                    height: 30; radius: 9
                    color: tinker.animOn ? tinker.pal.c5 : tinker.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: tinker.animOn ? "󰚀 Animations: ON" : "󰶐 Animations: OFF"
                        color: tinker.animOn ? tinker.pal.bg : tinker.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            tinker.animOn = !tinker.animOn
                            tinker.dirty = true
                            tinker.gearAngle += 30
                            tinker.cycleTool()
                            Quickshell.execDetached(["hyprctl", "keyword", "animations:enabled", tinker.animOn ? "true" : "false"])
                            autoSaveTimer.restart()
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) * 0.48
                    height: 34; radius: 10
                    color: tinker.savedFlash ? tinker.pal.c10 : tinker.pal.c11
                    Text {
                        anchors.centerIn: parent
                        text: tinker.savedFlash ? "✓ SAVED TO LUA!" : "󰆓 SAVE SETTINGS"
                        color: tinker.pal.bg
                        font.family: "Orbitron"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: tinker.saveToConfig()
                    }
                }

                Rectangle {
                    width: (parent.width - 8) * 0.52
                    height: 34; radius: 10
                    color: editMouse.containsMouse ? tinker.pal.c4 : tinker.pal.c0
                    border.color: tinker.pal.c4
                    border.width: 2
                    Text {
                        anchors.centerIn: parent
                        text: "󰅩 EDIT HYPRLAND.LUA"
                        color: editMouse.containsMouse ? tinker.pal.bg : tinker.pal.c4
                        font.family: "Orbitron"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    MouseArea {
                        id: editMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: tinker.openHyprlandLua()
                    }
                }
            }
        }
    }

    // 4. Single Central Unicycle Wheel / Spring Base Underneath!
    Rectangle {
        width: 48; height: 24; radius: 12
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: 28
        y: 516
        color: tinker.pal.bg
        border.color: tinker.pal.c11
        border.width: 4
    }
}
