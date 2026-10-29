import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: chime
    width: 420
    height: 510

    property var pal
    property string clockStr: "00:00"
    property string secStr: "00"
    property string dateStr: "SUN OCT 25"

    // Exposed active badge string for the Top Bar Clock Pill!
    readonly property string barBadge: ringing
        ? "🔔 RING!"
        : (pomoRunning ? ("🍅 " + formatSec(pomoSeconds)) : (timerRunning ? ("⏳ " + formatSec(timerSeconds)) : ""))

    property string activeTab: "pomo" // "pomo", "timer", "alarm"
    property bool ringing: false
    property string ringReason: "TIME'S UP!"
    property real bellPhase: 0

    // 1. Pomodoro State
    property int pomoSeconds: 25 * 60
    property int pomoTotal: 25 * 60
    property bool pomoRunning: false
    property string pomoMode: "FOCUS 25M"

    // 2. Custom Countdown Timer State
    property int timerSeconds: 5 * 60
    property int timerTotal: 5 * 60
    property bool timerRunning: false

    // 3. Daily Alarms State (Persisted to ~/.config/rice/chime-alarms.json)
    property var alarms: [
        { hr: 7,  min: 30, label: "Morning Wakeup", enabled: false },
        { hr: 13, min: 0,  label: "Afternoon Check", enabled: false },
        { hr: 18, min: 30, label: "Evening Call / Prep", enabled: false }
    ]
    property string lastTriggeredMinute: ""

    MouseArea { anchors.fill: parent; z: -1 }

    function formatSec(sec) {
        const m = Math.floor(sec / 60)
        const s = sec % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    function pad2(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function triggerRing(reason) {
        ringing = true
        ringReason = reason
        Quickshell.execDetached(["paplay", Quickshell.env("HOME") + "/rice/picker-qs/twinkle.wav"])
    }

    function stopRing() {
        ringing = false
    }

    function saveAlarms() {
        const jsonStr = JSON.stringify(chime.alarms)
        Quickshell.execDetached(["sh", "-c", "mkdir -p ~/.config/rice && printf '%s' '" + jsonStr + "' > ~/.config/rice/chime-alarms.json"])
    }

    Component.onCompleted: {
        loadAlarmsProc.running = true
    }

    Process {
        id: loadAlarmsProc
        command: ["sh", "-c", "cat ~/.config/rice/chime-alarms.json 2>/dev/null || true"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim())
                    if (Array.isArray(parsed) && parsed.length === 3) {
                        chime.alarms = parsed
                    }
                } catch (e) {}
            }
        }
    }

    // Master 1-Second Timekeeper (Updates :SS, Pomodoro, Countdown Timer & Checks Alarms!)
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            chime.secStr = chime.pad2(now.getSeconds())

            // A. Tick Pomodoro
            if (chime.pomoRunning) {
                if (chime.pomoSeconds > 0) {
                    chime.pomoSeconds--
                } else {
                    chime.pomoRunning = false
                    chime.triggerRing("POMODORO " + chime.pomoMode + " COMPLETE!")
                }
            }

            // B. Tick Countdown Timer
            if (chime.timerRunning) {
                if (chime.timerSeconds > 0) {
                    chime.timerSeconds--
                } else {
                    chime.timerRunning = false
                    chime.triggerRing("COUNTDOWN TIMER FINISHED!")
                }
            }

            // C. Check Daily Alarms (Triggers at :00 seconds of matching HH:MM)
            const curH = now.getHours()
            const curM = now.getMinutes()
            const key = curH + ":" + curM
            if (chime.lastTriggeredMinute !== key && now.getSeconds() < 3) {
                for (let i = 0; i < chime.alarms.length; i++) {
                    const a = chime.alarms[i]
                    if (a.enabled && a.hr === curH && a.min === curM) {
                        chime.lastTriggeredMinute = key
                        chime.triggerRing("ALARM: " + a.label.toUpperCase())
                        break
                    }
                }
            }

            // Repeat chime sound every 3 seconds while ringing
            if (chime.ringing && (now.getSeconds() % 3 === 0)) {
                Quickshell.execDetached(["paplay", Quickshell.env("HOME") + "/rice/picker-qs/twinkle.wav"])
            }
        }
    }

    // Fast Animation Timer for Bell Jingle & Pendulum Tick
    Timer {
        interval: 35
        running: chime.visible || chime.ringing
        repeat: true
        onTriggered: chime.bellPhase = (chime.bellPhase + 1) % 1000
    }

    // 1. Pointed Wall-Cat-Clock Ears & Top Hanging Wall Nail!
    // Wall Mounting Ring at Very Top
    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2
        color: "transparent"
        border.color: chime.pal.c11; border.width: 3
    }

    // Left Pointed Cat Ear
    Rectangle {
        width: 38; height: 38; radius: 6
        x: 132; y: 18
        rotation: 32
        color: chime.pal.bg
        border.color: chime.ringing ? chime.pal.c1 : chime.pal.c11
        border.width: 3
        Rectangle {
            width: 18; height: 18; radius: 3
            anchors.centerIn: parent
            color: chime.pal.c6; opacity: 0.65
        }
    }

    // Right Pointed Cat Ear
    Rectangle {
        width: 38; height: 38; radius: 6
        x: 250; y: 18
        rotation: 58
        color: chime.pal.bg
        border.color: chime.ringing ? chime.pal.c1 : chime.pal.c11
        border.width: 3
        Rectangle {
            width: 18; height: 18; radius: 3
            anchors.centerIn: parent
            color: chime.pal.c6; opacity: 0.65
        }
    }

    // 2. Chime's Retro Kit-Cat Klock Head (Rolling Crescent-Moon Eyes + Whiskers!)
    Rectangle {
        width: 176; height: 74; radius: 36
        anchors.horizontalCenter: parent.horizontalCenter
        y: 26
        color: chime.pal.bg
        border.color: chime.ringing ? chime.pal.c1 : chime.pal.c11
        border.width: 3

        MouseArea { anchors.fill: parent }

        // Whiskers Left & Right
        Repeater {
            model: 2
            Rectangle {
                width: 26; height: 2.5; radius: 1
                color: chime.pal.fg; opacity: 0.75
                x: -16; y: 40 + index * 10
                rotation: -10 + index * 18
            }
        }
        Repeater {
            model: 2
            Rectangle {
                width: 26; height: 2.5; radius: 1
                color: chime.pal.fg; opacity: 0.75
                x: 166; y: 40 + index * 10
                rotation: 10 - index * 18
            }
        }

        // Authentic Kit-Cat Klock Eyes (White Sclera + Shifting Pupil + Crescent Moon Cutout!)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            spacing: 20
            Repeater {
                model: 2
                Rectangle {
                    width: 44; height: 44; radius: 22
                    color: "#f5f7fa"
                    border.color: chime.pal.c0
                    border.width: 2.5
                    clip: true

                    // Rolling Black Pupil + Crescent Moon Segment Going Back & Forth!
                    Item {
                        readonly property real swing: Math.sin(chime.bellPhase * (chime.ringing ? 0.95 : 0.14)) * 9
                        width: 30; height: 30
                        x: 7 + swing
                        y: 7 - Math.abs(swing) * 0.18

                        // Main Dark Pupil Circle
                        Rectangle {
                            anchors.fill: parent
                            radius: 15
                            color: chime.ringing ? chime.pal.c1 : "#11131a"
                        }

                        // White Crescent-Moon Cutout Wedge Inside the Pupil (Gives That Classic Kit-Cat Look!)
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            x: 12 + Math.sin(chime.bellPhase * 0.14) * 3
                            y: 4
                            color: "#f5f7fa"
                        }
                    }
                }
            }
        }

        // Little Pink Triangle Cat Nose & Bowtie
        Rectangle {
            width: 10; height: 10; radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            y: 50
            rotation: 45
            color: chime.pal.c6
        }
    }

    // 3. Chime's Timekeeper Belly (Big Clock + Pomodoro / Timer / Alarms Deck)
    Rectangle {
        width: 394
        height: 374
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 98
        color: chime.pal.bg
        border.color: chime.ringing ? chime.pal.c1 : chime.pal.c11
        border.width: 3

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10

            // Dismiss Ringing Banner (Appears when Alarm/Timer/Pomo goes off!)
            Rectangle {
                visible: chime.ringing
                width: parent.width
                height: 40; radius: 12
                color: (Math.floor(chime.bellPhase / 6) % 2 === 0) ? chime.pal.c1 : chime.pal.c11
                Text {
                    anchors.centerIn: parent
                    text: "🔔 " + chime.ringReason + " (CLICK TO STOP)"
                    color: chime.pal.bg
                    font.family: "Orbitron"
                    font.pixelSize: 10
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: chime.stopRing()
                }
            }

            // A. Giant Big-Clock Display with Live Seconds (:SS)
            Rectangle {
                visible: !chime.ringing
                width: parent.width
                height: 76
                radius: 18
                color: Qt.darker(chime.pal.bg, 1.42)
                border.color: chime.pal.c0; border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: chime.clockStr
                        color: chime.pal.c11
                        font.family: "DSEG7 Classic"
                        font.pixelSize: 38
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: ":" + chime.secStr
                            color: chime.pal.c3
                            font.family: "DSEG7 Classic"
                            font.pixelSize: 16
                        }
                        Text {
                            text: "LOCAL"
                            color: chime.pal.c8
                            font.family: "Orbitron"
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }
            }

            // B. 3-Mode Timekeeper Tab Switcher (POMODORO | TIMER | ALARMS)
            Row {
                width: parent.width
                spacing: 8

                Repeater {
                    model: [
                        { id: "pomo",  label: "🍅 POMODORO", col: "c5" },
                        { id: "timer", label: "⏳ TIMER",    col: "c4" },
                        { id: "alarm", label: "⏰ ALARMS",   col: "c11" }
                    ]
                    Rectangle {
                        readonly property bool isCur: chime.activeTab === modelData.id
                        readonly property color tCol: chime.pal[modelData.col] || chime.pal.c11
                        width: (parent.width - 16) / 3
                        height: 32; radius: 10
                        color: isCur ? tCol : chime.pal.c0
                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: isCur ? chime.pal.bg : chime.pal.fg
                            font.family: "Orbitron"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: chime.activeTab = modelData.id
                        }
                    }
                }
            }

            // =================================================================
            // TAB 1: POMODORO FOCUS DECK
            // =================================================================
            Rectangle {
                visible: chime.activeTab === "pomo"
                width: parent.width
                height: 210
                radius: 18
                color: Qt.darker(chime.pal.bg, 1.35)
                border.color: chime.pomoRunning ? chime.pal.c10 : chime.pal.c8
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width * 0.6
                            text: "MODE // " + chime.pomoMode
                            color: chime.pal.c5
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            width: parent.width * 0.4
                            horizontalAlignment: Text.AlignRight
                            text: chime.pomoRunning ? "● RUNNING" : "○ PAUSED"
                            color: chime.pomoRunning ? chime.pal.c10 : chime.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    // Giant Pomodoro Countdown Readout + Start / Reset
                    Row {
                        width: parent.width
                        spacing: 12

                        Text {
                            width: parent.width * 0.52
                            anchors.verticalCenter: parent.verticalCenter
                            text: chime.formatSec(chime.pomoSeconds)
                            color: chime.pomoRunning ? chime.pal.c10 : chime.pal.fg
                            font.family: "DSEG7 Classic"
                            font.pixelSize: 32
                        }

                        Rectangle {
                            width: 84; height: 38; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: chime.pomoRunning ? chime.pal.c1 : chime.pal.c10
                            Text {
                                anchors.centerIn: parent
                                text: chime.pomoRunning ? "󰏤 PAUSE" : "󰐊 START"
                                color: chime.pal.bg
                                font.family: "Orbitron"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: chime.pomoRunning = !chime.pomoRunning
                            }
                        }

                        Rectangle {
                            width: 60; height: 38; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: chime.pal.c0
                            border.color: chime.pal.c8; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "RESET"
                                color: chime.pal.fg
                                font.family: "Orbitron"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    chime.pomoRunning = false
                                    chime.pomoSeconds = chime.pomoTotal
                                }
                            }
                        }
                    }

                    // Progress Bar
                    Rectangle {
                        width: parent.width; height: 10; radius: 5
                        color: Qt.darker(chime.pal.bg, 1.55)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, chime.pomoSeconds / Math.max(1, chime.pomoTotal)))
                            height: parent.height; radius: 5
                            color: chime.pomoRunning ? chime.pal.c10 : chime.pal.c5
                        }
                    }

                    // Presets (25m Focus / 5m Break / 15m Long Break)
                    Row {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "25M FOCUS", mins: 25, col: "c5" },
                                { label: "5M BREAK",  mins: 5,  col: "c4" },
                                { label: "15M CHILL", mins: 15, col: "c6" }
                            ]
                            Rectangle {
                                readonly property color pCol: chime.pal[modelData.col] || chime.pal.c5
                                width: (parent.width - 16) / 3
                                height: 30; radius: 8
                                color: chime.pomoTotal === modelData.mins * 60 ? pCol : chime.pal.c0
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: chime.pomoTotal === modelData.mins * 60 ? chime.pal.bg : chime.pal.fg
                                    font.family: "Orbitron"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        chime.pomoRunning = false
                                        chime.pomoTotal = modelData.mins * 60
                                        chime.pomoSeconds = chime.pomoTotal
                                        chime.pomoMode = modelData.label
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // TAB 2: CUSTOM COUNTDOWN TIMER DECK
            // =================================================================
            Rectangle {
                visible: chime.activeTab === "timer"
                width: parent.width
                height: 210
                radius: 18
                color: Qt.darker(chime.pal.bg, 1.35)
                border.color: chime.timerRunning ? chime.pal.c4 : chime.pal.c8
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width * 0.65
                            text: "CUSTOM COUNTDOWN TIMER"
                            color: chime.pal.c4
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            width: parent.width * 0.35
                            horizontalAlignment: Text.AlignRight
                            text: "WHEEL TO ADJUST"
                            color: chime.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        // Scrollable Timer Display
                        Item {
                            width: parent.width * 0.52
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chime.formatSec(chime.timerSeconds)
                                color: chime.timerRunning ? chime.pal.c4 : chime.pal.fg
                                font.family: "DSEG7 Classic"
                                font.pixelSize: 32
                            }
                            MouseArea {
                                anchors.fill: parent
                                onWheel: wheel => {
                                    const step = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 60 : -60
                                    chime.timerSeconds = Math.max(10, chime.timerSeconds + step)
                                    chime.timerTotal = chime.timerSeconds
                                }
                            }
                        }

                        Rectangle {
                            width: 84; height: 38; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: chime.timerRunning ? chime.pal.c1 : chime.pal.c4
                            Text {
                                anchors.centerIn: parent
                                text: chime.timerRunning ? "󰏤 PAUSE" : "󰐊 START"
                                color: chime.pal.bg
                                font.family: "Orbitron"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: chime.timerRunning = !chime.timerRunning
                            }
                        }

                        Rectangle {
                            width: 60; height: 38; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: chime.pal.c0
                            border.color: chime.pal.c8; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "CLEAR"
                                color: chime.pal.fg
                                font.family: "Orbitron"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    chime.timerRunning = false
                                    chime.timerSeconds = 0
                                    chime.timerTotal = 60
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 10; radius: 5
                        color: Qt.darker(chime.pal.bg, 1.55)
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, chime.timerSeconds / Math.max(1, chime.timerTotal)))
                            height: parent.height; radius: 5
                            color: chime.pal.c4
                        }
                    }

                    // Quick Time Adder Buttons (+30s, +1m, +5m, +10m)
                    Row {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: [
                                { label: "+30S", sec: 30 },
                                { label: "+1M",  sec: 60 },
                                { label: "+5M",  sec: 300 },
                                { label: "+10M", sec: 600 }
                            ]
                            Rectangle {
                                width: (parent.width - 24) / 4
                                height: 30; radius: 8
                                color: chime.pal.c0
                                border.color: chime.pal.c4; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: chime.pal.c4
                                    font.family: "Orbitron"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        chime.timerSeconds += modelData.sec
                                        chime.timerTotal = Math.max(chime.timerTotal, chime.timerSeconds)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // TAB 3: DAILY ALARMS DECK (Scrollable HH : MM + Arm/Disarm Switch!)
            // =================================================================
            Rectangle {
                visible: chime.activeTab === "alarm"
                width: parent.width
                height: 210
                radius: 18
                color: Qt.darker(chime.pal.bg, 1.35)
                border.color: chime.pal.c8
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width * 0.55
                            text: "DAILY ALARMS"
                            color: chime.pal.c11
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            width: parent.width * 0.45
                            horizontalAlignment: Text.AlignRight
                            text: "SCROLL HH:MM TO SET"
                            color: chime.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }

                    Repeater {
                        model: chime.alarms
                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 10
                            color: modelData.enabled ? Qt.darker(chime.pal.c11, 1.75) : chime.pal.c0
                            border.color: modelData.enabled ? chime.pal.c11 : chime.pal.c8
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 10
                                spacing: 8

                                // Hour Box (Scroll or Click to increment Hour)
                                Rectangle {
                                    width: 40; height: 32; radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: chime.pal.bg
                                    border.color: chime.pal.c11; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: chime.pad2(modelData.hr)
                                        color: chime.pal.c11
                                        font.family: "DSEG7 Classic"
                                        font.pixelSize: 15
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            let copy = chime.alarms.slice()
                                            copy[index].hr = (copy[index].hr + 1) % 24
                                            chime.alarms = copy
                                            chime.saveAlarms()
                                        }
                                        onWheel: wheel => {
                                            let copy = chime.alarms.slice()
                                            const d = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 1 : -1
                                            copy[index].hr = (copy[index].hr + d + 24) % 24
                                            chime.alarms = copy
                                            chime.saveAlarms()
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: ":"
                                    color: chime.pal.fg
                                    font.family: "DSEG7 Classic"
                                    font.pixelSize: 15
                                }

                                // Minute Box (Scroll or Click to adjust Minute by 5m / 1m)
                                Rectangle {
                                    width: 40; height: 32; radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: chime.pal.bg
                                    border.color: chime.pal.c11; border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: chime.pad2(modelData.min)
                                        color: chime.pal.c11
                                        font.family: "DSEG7 Classic"
                                        font.pixelSize: 15
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            let copy = chime.alarms.slice()
                                            copy[index].min = (copy[index].min + 5) % 60
                                            chime.alarms = copy
                                            chime.saveAlarms()
                                        }
                                        onWheel: wheel => {
                                            let copy = chime.alarms.slice()
                                            const d = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 1 : -1
                                            copy[index].min = (copy[index].min + d + 60) % 60
                                            chime.alarms = copy
                                            chime.saveAlarms()
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width - 178
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: chime.pal.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: modelData.enabled
                                    elide: Text.ElideRight
                                }

                                // Arm / Disarm Toggle Pill
                                Rectangle {
                                    width: 60; height: 28; radius: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData.enabled ? chime.pal.c10 : chime.pal.bg
                                    border.color: modelData.enabled ? chime.pal.fg : chime.pal.c8
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.enabled ? "ARMED" : "OFF"
                                        color: modelData.enabled ? chime.pal.bg : chime.pal.c8
                                        font.family: "Orbitron"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            let copy = chime.alarms.slice()
                                            copy[index].enabled = !copy[index].enabled
                                            chime.alarms = copy
                                            chime.saveAlarms()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 4. Swinging Kit-Cat Klock Tail & White Cat Paws Underneath!
    Item {
        width: 80; height: 60
        anchors.horizontalCenter: parent.horizontalCenter
        y: 462
        z: -1
        transformOrigin: Item.Top
        rotation: -Math.sin(chime.bellPhase * (chime.ringing ? 0.95 : 0.14)) * 30

        // Long Curved Cat Tail
        Rectangle {
            width: 16; height: 48; radius: 8
            anchors.horizontalCenter: parent.horizontalCenter
            color: chime.pal.bg
            border.color: chime.pal.c11; border.width: 3
        }
        // White Tail Tip
        Rectangle {
            width: 18; height: 18; radius: 9
            anchors.horizontalCenter: parent.horizontalCenter
            y: 36
            color: chime.pal.fg
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 474
        spacing: 125
        Repeater {
            model: 2
            Rectangle {
                width: 48; height: 20; radius: 10
                color: "#f5f7fa"
                border.color: chime.pal.c11
                border.width: 3
            }
        }
    }
}
