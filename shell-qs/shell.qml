import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")

    // 1. Live Wallust Palette State
    property string lastPalHash: ""
    property var pal: ({
        bg: "#11131a", fg: "#e5e9f0",
        c0: "#1b1e28", c1: "#ff5555", c2: "#50fa7b", c3: "#f1fa8c",
        c4: "#8be9fd", c5: "#bd93f9", c6: "#ff79c6", c7: "#e5e9f0",
        c8: "#6272a4", c9: "#ff6e6e", c10: "#69ff94", c11: "#ffffa5",
        c12: "#a4ffff", c13: "#d6acff", c14: "#ff92df", c15: "#ffffff"
    })

    property var sys: ({
        cpu: 0, ram: 0, gpu: 0, gputemp: 0, gpumem: 0,
        vol: 50, micvol: 82, micon: true, bri: 80, bat: 100, bat_stat: "Plugged", bat_watt: "0.0", pwr_mode: "balanced",
        bat: 100, batstat: "AC", ssid: "Online", bton: true,
        pstat: "Stopped", title: "Nothing Playing", artist: "Shellby FM", album: "", art: ""
    })

    property var weatherData: ({ temp: "72°F", desc: "Clear Sky", icon: "󰖙" })
    property var appListData: []
    property string activeCard: ""      // "", "shellby", "launcher", "boiler", "fader", "blinky", "tinker", "sundial"
    property string pendingCard: ""
    property string clockStr: "00:00"
    property string dateStr: "SUN OCT 25"

    // Track Active Hyprland Workspace & Trigger Zippy Escort on Change!
    readonly property int activeWsId: Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace
        ? Hyprland.focusedMonitor.activeWorkspace.id : 1
    property bool wsArmed: false
    Timer { interval: 800; running: true; onTriggered: root.wsArmed = true }
    onActiveWsIdChanged: {
        if (wsArmed && activeWsId >= 1 && activeWsId <= 10) {
            zippyEscort.summon(activeWsId)
        }
    }

    // 2. Two-Stage Parabolic Flight + Organic Paint Ooze State
    property real dropProgress: 0
    property real splatProgress: 0
    property bool dropping: false
    property bool splatting: false

    property real startX: 960
    property real startY: 32
    property real targetX: 250
    property real targetY: 800
    property real targetW: 400
    property real targetH: 360
    property real arcHeight: 150
    property color dropColor: root.pal.c5

    readonly property real screenW: barWin.width > 0 ? barWin.width : 1920
    readonly property real screenH: overlayWin.height > 0 ? overlayWin.height : 1080

    // Screen Landing Coordinates for All 7 Menagerie Buddies
    readonly property real shellbyCenterX: 255
    readonly property real shellbyCenterY: screenH - 255

    readonly property real launcherCenterX: screenW * 0.5
    readonly property real launcherCenterY: screenH * 0.5

    readonly property real boilerCenterX: 245
    readonly property real boilerCenterY: 280

    readonly property real faderCenterX: screenW - 235
    readonly property real faderCenterY: 265

    readonly property real blinkyCenterX: screenW - 250
    readonly property real blinkyCenterY: screenH - 255

    readonly property real tinkerCenterX: screenW * 0.68
    readonly property real tinkerCenterY: screenH * 0.52

    readonly property real sundialCenterX: screenW * 0.32
    readonly property real sundialCenterY: screenH * 0.50

    readonly property real chimeCenterX: screenW * 0.68
    readonly property real chimeCenterY: screenH * 0.52

    readonly property real juiceCenterX: screenW - 235
    readonly property real juiceCenterY: 265

    // Current droplet position & velocity angle along the parabola
    readonly property real curDropX: startX + (targetX - startX) * dropProgress
    readonly property real curDropY: startY + (targetY - startY) * (dropProgress * dropProgress) - Math.sin(dropProgress * Math.PI) * arcHeight
    readonly property real velX: (targetX - startX)
    readonly property real velY: 2 * (targetY - startY) * dropProgress - Math.cos(dropProgress * Math.PI) * Math.PI * arcHeight
    readonly property real dropAngle: Math.atan2(velY, velX) * 180 / Math.PI

    // Non-Uniform Viscous Ooze Curves
    readonly property real cardReveal: Math.max(0.0, Math.min(1.0, (splatProgress - 0.12) / 0.88))
    readonly property real cardScaleX: 1.0 - Math.pow(1.0 - cardReveal, 3.4)
    readonly property real cardScaleY: 1.0 - Math.pow(1.0 - Math.max(0.0, (splatProgress - 0.24) / 0.76), 2.3)

    function triggerCard(name, originItem) {
        if (activeCard === name && !dropping) {
            closeAnim.restart()
            return
        }

        if (originItem) {
            const pt = originItem.mapToItem(null, originItem.width * 0.5, originItem.height * 0.5)
            startX = pt.x
        } else {
            startX = screenW * 0.5
        }
        startY = 28

        if (name === "shellby") {
            targetX = shellbyCenterX; targetY = shellbyCenterY
            targetW = 400; targetH = 380; arcHeight = 185
            dropColor = root.pal.c5
        } else if (name === "launcher") {
            targetX = launcherCenterX; targetY = launcherCenterY
            targetW = 460; targetH = 440; arcHeight = 135
            dropColor = root.pal.c13
        } else if (name === "boiler") {
            targetX = boilerCenterX; targetY = boilerCenterY
            targetW = 372; targetH = 390; arcHeight = 140
            dropColor = root.pal.c4
        } else if (name === "fader") {
            targetX = faderCenterX; targetY = faderCenterY
            targetW = 360; targetH = 360; arcHeight = 140
            dropColor = root.pal.c6
        } else if (name === "blinky") {
            targetX = blinkyCenterX; targetY = blinkyCenterY
            targetW = 390; targetH = 390; arcHeight = 180
            dropColor = root.pal.c10
        } else if (name === "tinker") {
            targetX = tinkerCenterX; targetY = tinkerCenterY
            targetW = 410; targetH = 440; arcHeight = 155
            dropColor = root.pal.c11
        } else if (name === "sundial") {
            targetX = sundialCenterX; targetY = sundialCenterY
            targetW = 404; targetH = 420; arcHeight = 155
            dropColor = root.pal.c3
        } else if (name === "chime") {
            targetX = chimeCenterX; targetY = chimeCenterY
            targetW = 394; targetH = 410; arcHeight = 155
            dropColor = root.pal.c11
        } else if (name === "juice") {
            targetX = juiceCenterX; targetY = juiceCenterY
            targetW = 356; targetH = 350; arcHeight = 140
            dropColor = root.pal.c11
        }

        pendingCard = name
        activeCard = ""
        splatProgress = 0
        dropProgress = 0
        splatting = false
        dropping = true
        flightAnim.restart()
    }

    NumberAnimation {
        id: flightAnim
        target: root
        property: "dropProgress"
        from: 0; to: 1
        duration: 680
        easing.type: Easing.InSine
        onFinished: {
            root.dropping = false
            root.activeCard = root.pendingCard
            root.splatting = true
            splatSpreadAnim.restart()
            if (root.activeCard === "launcher") {
                launcherItem.focusSearch()
            }
        }
    }

    NumberAnimation {
        id: splatSpreadAnim
        target: root
        property: "splatProgress"
        from: 0.0; to: 1.0
        duration: 960
        easing.type: Easing.OutCubic
        onFinished: {
            root.splatting = false
        }
    }

    NumberAnimation {
        id: closeAnim
        target: root
        property: "splatProgress"
        from: 1.0; to: 0.0
        duration: 400
        easing.type: Easing.InCubic
        onStarted: root.splatting = true
        onFinished: {
            root.splatting = false
            root.activeCard = ""
            root.pendingCard = ""
        }
    }

    // 3. Reload Colors Automatically Whenever setwall Runs
    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: colorProc.running = true
    }

    Process {
        id: colorProc
        command: ["cat", root.home + "/rice/shell-qs/colors.json"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const clean = data.trim()
                    root.pal = JSON.parse(clean)
                    if (clean !== root.lastPalHash) {
                        root.lastPalHash = clean
                        Quickshell.execDetached([root.home + "/rice/scripts/sync-rgb"])
                    }
                } catch (e) {}
            }
        }
    }

    // 4. Poll System Telemetry, Weather & Clock
    Timer {
        interval: 1200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            sysProc.running = true
            const now = new Date()
            root.clockStr = Qt.formatTime(now, "hh:mm")
            root.dateStr = Qt.formatDate(now, "ddd MMM d").toUpperCase()
        }
    }

    Process {
        id: sysProc
        command: [root.home + "/rice/shell-qs/sysinfo.sh", "status"]
        stdout: SplitParser {
            onRead: line => {
                try { root.sys = JSON.parse(line) } catch (e) {}
            }
        }
    }

    Timer {
        interval: 300000 // Refresh cached weather every 5 mins
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    Process {
        id: weatherProc
        command: [root.home + "/rice/shell-qs/sysinfo.sh", "weather"]
        stdout: SplitParser {
            onRead: line => {
                try { root.weatherData = JSON.parse(line) } catch (e) {}
            }
        }
    }

    // 5. Load Desktop Apps Index Once on Startup
    Process {
        id: appsProc
        command: [root.home + "/rice/shell-qs/sysinfo.sh", "apps"]
        running: true
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try { root.appListData = JSON.parse(data) } catch (e) {}
            }
        }
    }

    // 6. Listen for External Keybind & OSD Commands (/tmp/shellby.cmd)
    Timer {
        interval: 120
        running: true
        repeat: true
        onTriggered: ipcProc.running = true
    }

    Process {
        id: ipcProc
        command: ["sh", "-c", "if [ -s /tmp/shellby.cmd ]; then cat /tmp/shellby.cmd; rm -f /tmp/shellby.cmd; fi"]
        stdout: SplitParser {
            onRead: line => {
                const cmd = line.trim()
                if (cmd === "launcher") root.triggerCard("launcher", launchPill)
                else if (cmd === "shellby") root.triggerCard("shellby", shellbyPill)
                else if (cmd === "boiler") root.triggerCard("boiler", boilerPill)
                else if (cmd === "fader" || cmd === "system") root.triggerCard("fader", volPill)
                else if (cmd === "blinky" || cmd === "net") root.triggerCard("blinky", netPill)
                else if (cmd === "tinker" || cmd === "settings") root.triggerCard("tinker", tinkerPill)
                else if (cmd === "sundial" || cmd === "calendar") root.triggerCard("sundial", sundialPill)
                else if (cmd === "chime" || cmd === "clock") root.triggerCard("chime", clockPill)
                else if (cmd === "juice" || cmd === "battery" || cmd === "power") root.triggerCard("juice", juicePill)
                else if (cmd === "vol-up") { faderItem.applyVol(faderItem.localVol + 5); peepOsd.trigger("vol", faderItem.localVol) }
                else if (cmd === "vol-down") { faderItem.applyVol(faderItem.localVol - 5); peepOsd.trigger("vol", faderItem.localVol) }
                else if (cmd === "bri-up") { faderItem.applyBri(faderItem.localBri + 5); peepOsd.trigger("bri", faderItem.localBri) }
                else if (cmd === "bri-down") { faderItem.applyBri(faderItem.localBri - 5); peepOsd.trigger("bri", faderItem.localBri) }
            }
        }
    }

    // =========================================================================
    // WINDOW 1: EXCLUSIVE TOP BAR WITH SEPARATE FLOATING ISLAND PILLS
    // =========================================================================
    PanelWindow {
        id: barWin
        anchors { top: true; left: true; right: true }
        implicitHeight: 52
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.exclusiveZone: 52
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "shellby-bar"

        mask: Region { item: islandsCluster }

        Row {
            id: islandsCluster
            anchors.centerIn: parent
            spacing: 10

            // PILL 1: Pounce (App Launcher Icon Pill)
            Rectangle {
                id: launchPill
                height: 36; width: 44; radius: 18
                color: root.activeCard === "launcher" ? root.pal.c13 : root.pal.bg
                border.color: root.pal.c13
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "🚀"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: root.activeCard === "launcher" ? root.pal.bg : root.pal.c13
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("launcher", launchPill)
                }
            }

            // PILL 2: Upgraded Hyprland Workspaces Track Pill (With Sliding Critter Car & Wheel Cycling!)
            Rectangle {
                id: wsPill
                height: 36
                width: 6 * 32 + 20
                radius: 18
                color: root.pal.bg
                border.color: root.pal.c5
                border.width: 2

                // Sliding Neon Critter Car Highlighting the Active Workspace!
                Rectangle {
                    id: wsRunner
                    width: 30; height: 24; radius: 12
                    y: 6
                    x: 10 + Math.max(0, Math.min(5, root.activeWsId - 1)) * 32
                    color: root.pal.c5
                    Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

                    // Little Critter Eyes inside the Active Workspace Car
                    Row {
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        Repeater {
                            model: 2
                            Rectangle {
                                width: 4; height: 4; radius: 2
                                color: root.pal.bg
                            }
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: 6
                        Item {
                            readonly property int wsId: index + 1
                            readonly property bool isFocused: root.activeWsId === wsId
                            width: 30; height: 26

                            Text {
                                anchors.centerIn: parent
                                text: "0" + wsId
                                color: isFocused ? root.pal.bg : root.pal.c8
                                font.family: "Orbitron"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", wsId.toString()])
                            }
                        }
                    }
                }

                // Scroll Mouse Wheel over Workspaces Pill to Cycle Workspaces!
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: wheel => {
                        const dir = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? -1 : 1
                        const nextWs = Math.max(1, Math.min(6, root.activeWsId + dir))
                        if (nextWs !== root.activeWsId) {
                            Quickshell.execDetached(["hyprctl", "dispatch", "workspace", nextWs.toString()])
                        }
                    }
                }
            }

            // PILL 3: Shellby (Media Star Pill)
            Rectangle {
                id: shellbyPill
                height: 36
                width: mediaRow.implicitWidth + 24
                radius: 18
                color: root.activeCard === "shellby" ? root.pal.c5 : root.pal.bg
                border.color: root.pal.c5
                border.width: 2

                Row {
                    id: mediaRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: root.sys.pstat === "Playing" ? "󰎈" : "󰚩"
                        color: root.activeCard === "shellby" ? root.pal.bg : root.pal.c10
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                    }
                    Text {
                        text: root.sys.pstat === "Playing" ? root.sys.title : "Shellby"
                        color: root.activeCard === "shellby" ? root.pal.bg : root.pal.fg
                        font.family: "Orbitron"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("shellby", shellbyPill)
                }
            }

            // PILL 4: Boiler (Telemetry Icon Pill)
            Rectangle {
                id: boilerPill
                height: 36; width: 44; radius: 18
                color: root.activeCard === "boiler" ? root.pal.c4 : root.pal.bg
                border.color: root.pal.c4
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "󰘚"
                    color: root.activeCard === "boiler" ? root.pal.bg : root.pal.c4
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("boiler", boilerPill)
                }
            }

            // PILL 4B: Live System Tray Pill (Shows running tray icons like OpenRGB, Discord, Steam)
                Rectangle {
                    id: sysTrayPill
                    visible: SystemTray.items.values.length > 0
                    height: 36
                    width: visible ? (trayInnerRow.implicitWidth + 20) : 0
                    radius: 18
                    color: root.pal.bg
                    border.color: root.pal.c8
                    border.width: 2

                    Row {
                        id: trayInnerRow
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: SystemTray.items
                            Item {
                                width: 18; height: 18
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                    smooth: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.LeftButton) {
                                            modelData.activate()
                                        } else {
                                            modelData.secondaryActivate()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // PILL 4C: Juice Pill (Battery Percentage + Power Governor Mode -> Summons Juice!)
                Rectangle {
                    id: juicePill
                    height: 36
                    width: juiceRow.implicitWidth + 22
                    radius: 18
                    color: root.activeCard === "juice" ? root.pal.c11 : root.pal.bg
                    border.color: root.sys.pwr_mode === "performance" ? root.pal.c1 : (root.sys.pwr_mode === "saver" ? root.pal.c10 : root.pal.c11)
                    border.width: 2

                    Row {
                        id: juiceRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: {
                                const st = root.sys.bat_stat || ""
                                const pct = Number(root.sys.bat !== undefined ? root.sys.bat : 100)
                                if (st === "Charging") return "󰂄"
                                if (pct >= 90) return "󰁹"
                                if (pct >= 70) return "󰂀"
                                if (pct >= 50) return "󰁾"
                                if (pct >= 25) return "󰁻"
                                return "󰁺"
                            }
                            color: root.activeCard === "juice" ? root.pal.bg : root.pal.c11
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                        Text {
                            text: (root.sys.bat !== undefined ? root.sys.bat : 100) + "%"
                            color: root.activeCard === "juice" ? root.pal.bg : root.pal.fg
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: root.sys.pwr_mode === "performance" ? "⚡" : (root.sys.pwr_mode === "saver" ? "🍃" : "⚖️")
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.triggerCard("juice", juicePill)
                    }
                }

                // PILL 5A: Dedicated Audio Pill (Mic + Speaker Volume % -> Wheel = Volume Only!)
                Rectangle {
                    id: volPill
                    height: 36
                    width: volPillRow.implicitWidth + 22
                    radius: 18
                    color: root.activeCard === "fader" ? root.pal.c6 : root.pal.bg
                    border.color: root.pal.c6
                    border.width: 2

                    Row {
                        id: volPillRow
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: root.sys.micon ? "󰍬" : "󰍭"
                            color: root.activeCard === "fader" ? root.pal.bg : (root.sys.micon ? root.pal.c2 : root.pal.c1)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        Text {
                            text: root.sys.mute === "true" ? "󰝟" : "󰕾"
                            color: root.activeCard === "fader" ? root.pal.bg : (root.sys.mute === "true" ? root.pal.c1 : root.pal.c6)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                        Text {
                            text: faderItem.localVol + "%"
                            color: root.activeCard === "fader" ? root.pal.bg : root.pal.fg
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                            } else {
                                root.triggerCard("fader", volPill)
                            }
                        }
                        onWheel: wheel => {
                            const vStep = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 4 : -4
                            const nextVol = Math.max(0, Math.min(150, faderItem.localVol + vStep))
                            faderItem.applyVol(nextVol)
                            peepOsd.trigger("vol", nextVol)
                        }
                    }
                }

                // PILL 5B: Dedicated Brightness Pill (Backlight % -> Wheel = Brightness Only!)
                Rectangle {
                    id: briPill
                    height: 36
                    width: briPillRow.implicitWidth + 22
                    radius: 18
                    color: root.activeCard === "fader" ? root.pal.c11 : root.pal.bg
                    border.color: root.pal.c11
                    border.width: 2

                    Row {
                        id: briPillRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰌵"
                            color: root.activeCard === "fader" ? root.pal.bg : root.pal.c11
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                        Text {
                            text: faderItem.localBri + "%"
                            color: root.activeCard === "fader" ? root.pal.bg : root.pal.fg
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.triggerCard("fader", briPill)
                        onWheel: wheel => {
                            const bStep = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 5 : -5
                            const nextBri = Math.max(5, Math.min(100, faderItem.localBri + bStep))
                            faderItem.applyBri(nextBri)
                            peepOsd.trigger("bri", nextBri)
                        }
                    }
                }

                // PILL 6: Blinky (Wi-Fi & Bluetooth Icon Pill)
            Rectangle {
                id: netPill
                height: 36; width: 64; radius: 18
                color: root.activeCard === "blinky" ? root.pal.c10 : root.pal.bg
                border.color: root.pal.c10
                border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: root.sys.ssid !== "Wired/Offline" ? "󰖩" : "󰖪"
                        color: root.activeCard === "blinky" ? root.pal.bg : root.pal.c10
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }
                    Text {
                        text: root.sys.bton ? "󰂯" : "󰂲"
                        color: root.activeCard === "blinky" ? root.pal.bg : root.pal.c4
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("blinky", netPill)
                }
            }

            // PILL 7: Tinker (Hyprland Live Settings Gear Pill)
            Rectangle {
                id: tinkerPill
                height: 36; width: 44; radius: 18
                color: root.activeCard === "tinker" ? root.pal.c11 : root.pal.bg
                border.color: root.pal.c11
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "󰒓"
                    color: root.activeCard === "tinker" ? root.pal.bg : root.pal.c11
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("tinker", tinkerPill)
                }
            }

            // PILL 8: Sundial (Weather + Date Schedule Pill -> Summons Sundial the Planner Owl!)
            Rectangle {
                id: sundialPill
                height: 36
                width: sundialRow.implicitWidth + 24
                radius: 18
                color: root.activeCard === "sundial" ? root.pal.c3 : root.pal.bg
                border.color: root.pal.c3
                border.width: 2

                Row {
                    id: sundialRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: root.weatherData.icon || "󰖙"
                        color: root.activeCard === "sundial" ? root.pal.bg : root.pal.c3
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }
                    Text {
                        text: root.weatherData.temp || "72°F"
                        color: root.activeCard === "sundial" ? root.pal.bg : root.pal.c12
                        font.family: "Orbitron"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    Text {
                        text: "󰃭 " + root.dateStr
                        color: root.activeCard === "sundial" ? root.pal.bg : root.pal.fg
                        font.family: "Orbitron"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("sundial", sundialPill)
                }
            }

            // PILL 9: Chime (Digital Clock + Live Pomodoro/Timer Badge -> Summons Chime the Alarm/Timer Buddy!)
            Rectangle {
                id: clockPill
                height: 36
                width: clockRow.implicitWidth + 24
                radius: 18
                color: chimeItem.ringing ? root.pal.c1 : (root.activeCard === "chime" ? root.pal.c11 : root.pal.bg)
                border.color: chimeItem.ringing ? root.pal.fg : root.pal.c11
                border.width: 2

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰥔"
                        color: (root.activeCard === "chime" || chimeItem.ringing) ? root.pal.bg : root.pal.c11
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }
                    Text {
                        text: root.clockStr
                        color: (root.activeCard === "chime" || chimeItem.ringing) ? root.pal.bg : root.pal.c11
                        font.family: "DSEG7 Classic"
                        font.pixelSize: 14
                    }
                    Text {
                        visible: chimeItem.barBadge !== ""
                        text: chimeItem.barBadge
                        color: (root.activeCard === "chime" || chimeItem.ringing) ? root.pal.bg : root.pal.c10
                        font.family: "Orbitron"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.triggerCard("chime", clockPill)
                }
            }
        }
    }

    // =========================================================================
    // WINDOW 2: OVERLAY SPLAT CANVAS, 7-BUDDY MENAGERIE, PEEP OSD & ZIPPY ESCORT
    // =========================================================================
    PanelWindow {
        id: overlayWin
        visible: root.dropping || root.splatting || root.activeCard !== ""
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: (root.activeCard === "launcher" || root.activeCard === "blinky" || root.activeCard === "sundial")
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shellby-overlay"

        MouseArea {
            anchors.fill: parent
            enabled: root.activeCard !== "" && !root.dropping
            onClicked: closeAnim.restart()
        }

        // 1. Parabolic Splat Droplet in Flight
        Item {
            visible: root.dropping
            x: root.curDropX
            y: root.curDropY
            rotation: root.dropAngle

            Rectangle {
                width: 44; height: 12; radius: 6
                x: -38; y: -6
                color: root.dropColor
                opacity: 0.48
            }

            Rectangle {
                width: 30 + Math.sin(root.dropProgress * Math.PI) * 14
                height: 18 - Math.sin(root.dropProgress * Math.PI) * 4
                radius: height / 2
                x: -width / 2; y: -height / 2
                color: root.dropColor
                border.color: root.pal.fg
                border.width: 2
            }
        }

        // 2. Organic Multi-Lobe Paint Blob Splat & Viscous Ooze
        Item {
            id: paintSplat
            visible: root.splatting
            x: root.targetX
            y: root.targetY

            Rectangle {
                readonly property real p: Math.min(1.0, root.splatProgress * 1.25)
                width: 36 + p * (root.targetW * 0.98)
                height: 36 + Math.pow(p, 1.35) * (root.targetH * 0.94)
                radius: (1.0 - p * 0.65) * (height / 2) + 26
                x: -width / 2; y: -height / 2
                color: root.dropColor
                opacity: Math.max(0.0, 0.95 - Math.max(0.0, (root.splatProgress - 0.48) / 0.52))
            }

            Repeater {
                model: [
                    { dx: -0.46, dy: -0.36, rx: 145, ry: 110, rot: -22, lag: 1.35 },
                    { dx:  0.48, dy: -0.34, rx: 135, ry: 115, rot:  28, lag: 1.20 },
                    { dx: -0.50, dy:  0.35, rx: 155, ry: 120, rot:  18, lag: 1.30 },
                    { dx:  0.47, dy:  0.38, rx: 150, ry: 110, rot: -19, lag: 1.15 },
                    { dx:  0.00, dy: -0.45, rx: 170, ry:  95, rot:   6, lag: 1.40 },
                    { dx:  0.02, dy:  0.45, rx: 175, ry: 100, rot:  -8, lag: 1.25 },
                    { dx: -0.54, dy:  0.02, rx: 120, ry: 145, rot:  12, lag: 1.38 },
                    { dx:  0.54, dy: -0.03, rx: 125, ry: 140, rot: -14, lag: 1.28 }
                ]
                Rectangle {
                    readonly property real reach: Math.sin(Math.min(1.0, root.splatProgress * modelData.lag) * Math.PI * 0.65)
                    width: 28 + reach * modelData.rx
                    height: 28 + reach * modelData.ry
                    radius: Math.min(width, height) * 0.48
                    x: modelData.dx * root.targetW * reach - width / 2
                    y: modelData.dy * root.targetH * reach - height / 2
                    rotation: modelData.rot * reach
                    color: index % 2 === 0 ? root.dropColor : Qt.lighter(root.dropColor, 1.12)
                    opacity: Math.max(0.0, 0.92 - Math.max(0.0, (root.splatProgress - 0.45) / 0.55))
                }
            }

            Repeater {
                model: [
                    { ang:  0.45, dist: 1.18, sz: 22 },
                    { ang:  1.35, dist: 1.12, sz: 16 },
                    { ang:  2.55, dist: 1.22, sz: 24 },
                    { ang:  3.65, dist: 1.16, sz: 18 },
                    { ang:  4.65, dist: 1.14, sz: 20 },
                    { ang:  5.75, dist: 1.20, sz: 17 }
                ]
                Rectangle {
                    readonly property real burst: Math.pow(root.splatProgress, 0.42)
                    width: modelData.sz * (1.15 - root.splatProgress * 0.5)
                    height: width * 0.78
                    radius: height / 2
                    rotation: modelData.ang * 57.3
                    x: Math.cos(modelData.ang) * (root.targetW * 0.5 * modelData.dist * burst) - width / 2
                    y: Math.sin(modelData.ang) * (root.targetH * 0.5 * modelData.dist * burst) - height / 2
                    color: root.dropColor
                    opacity: Math.max(0.0, 0.95 - Math.pow(root.splatProgress, 1.4))
                }
            }
        }

        // Buddy 1: Shellby (Lower-Left Hero Corner)
        ShellbyMascot {
            id: shellbyItem
            x: root.shellbyCenterX - width / 2
            y: root.shellbyCenterY - height / 2
            visible: root.activeCard === "shellby"
            pal: root.pal
            sys: root.sys
            transform: Scale {
                origin.x: shellbyItem.width / 2
                origin.y: shellbyItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 2: Pounce (App Launcher -> Dead Center)
        LauncherCard {
            id: launcherItem
            x: root.launcherCenterX - width / 2
            y: root.launcherCenterY - height / 2
            visible: root.activeCard === "launcher"
            pal: root.pal
            allApps: root.appListData
            onRequestClose: closeAnim.restart()
            transform: Scale {
                origin.x: launcherItem.width / 2
                origin.y: launcherItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 3: Boiler (Pure MSI Telemetry -> Upper-Left Quadrant)
        BoilerCard {
            id: boilerItem
            x: root.boilerCenterX - width / 2
            y: root.boilerCenterY - height / 2
            visible: root.activeCard === "boiler"
            pal: root.pal
            sys: root.sys
            transform: Scale {
                origin.x: boilerItem.width / 2
                origin.y: boilerItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 4: Fader (Audio, Mic & Brightness -> Upper-Right Quadrant)
        // Buddy 4A: Juice (High-Voltage Battery Cell & Power Governor -> Upper-Right Quadrant)
        JuiceCard {
            id: juiceItem
            x: root.juiceCenterX - width / 2
            y: root.juiceCenterY - height / 2
            visible: root.activeCard === "juice"
            pal: root.pal
            sys: root.sys
            transform: Scale {
                origin.x: juiceItem.width / 2
                origin.y: juiceItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

            FaderCard {
            id: faderItem
            x: root.faderCenterX - width / 2
            y: root.faderCenterY - height / 2
            visible: root.activeCard === "fader"
            pal: root.pal
            sys: root.sys
            transform: Scale {
                origin.x: faderItem.width / 2
                origin.y: faderItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 5: Blinky (Wi-Fi & Bluetooth Angler -> Lower-Right Corner)
        BlinkyCard {
            id: blinkyItem
            x: root.blinkyCenterX - width / 2
            y: root.blinkyCenterY - height / 2
            visible: root.activeCard === "blinky"
            pal: root.pal
            sys: root.sys
            transform: Scale {
                origin.x: blinkyItem.width / 2
                origin.y: blinkyItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 6: Tinker (Hyprland Live Settings Mech -> Center-Right)
        TinkerCard {
            id: tinkerItem
            x: root.tinkerCenterX - width / 2
            y: root.tinkerCenterY - height / 2
            visible: root.activeCard === "tinker"
            pal: root.pal
            onRequestClose: closeAnim.restart()
            transform: Scale {
                origin.x: tinkerItem.width / 2
                origin.y: tinkerItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 7: Sundial (Clock, Calendar, Weather & Pomodoro Owl -> Center-Left)
        SundialCard {
            id: sundialItem
            x: root.sundialCenterX - width / 2
            y: root.sundialCenterY - height / 2
            visible: root.activeCard === "sundial"
            pal: root.pal
            weather: root.weatherData
            clockStr: root.clockStr
            dateStr: root.dateStr
            transform: Scale {
                origin.x: sundialItem.width / 2
                origin.y: sundialItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

        // Buddy 8: Chime (Big Clock, Pomodoro, Countdown Timer & Alarms Buddy -> Center-Right)
        ChimeCard {
            id: chimeItem
            x: root.chimeCenterX - width / 2
            y: root.chimeCenterY - height / 2
            visible: root.activeCard === "chime"
            pal: root.pal
            clockStr: root.clockStr
            dateStr: root.dateStr
            transform: Scale {
                origin.x: chimeItem.width / 2
                origin.y: chimeItem.height / 2
                xScale: root.cardScaleX
                yScale: root.cardScaleY
            }
            opacity: Math.min(1.0, root.cardReveal * 1.4)
        }

    }

    // =========================================================================
    // WINDOW 3: NON-BLOCKING BOTTOM OSD & WORKSPACE ESCORT STRIP (PEEP & ZIPPY)
    // =========================================================================
    PanelWindow {
        id: osdWin
        visible: true
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 195
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "shellby-osd"

        // Buddy 9: Peep (Playful Pop-Up OSD Buddy for Volume & Brightness!)
        OsdBuddy {
            id: peepOsd
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            pal: root.pal
        }

        // Buddy 10: Zippy (Speedy Workspace Escort Courier!)
        WorkspaceEscort {
            id: zippyEscort
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            pal: root.pal
        }
    }
}
