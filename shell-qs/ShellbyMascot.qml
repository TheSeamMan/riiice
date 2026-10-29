import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Item {
    id: mascot
    width: 430
    height: 450

    property var pal
    property var sys: ({
        pstat: "Stopped",
        title: "Nothing Playing",
        artist: "Shellby FM",
        album: "",
        art: ""
    })

    // Live 16-bar FFT spectrum array fed directly by cava
    property var cavaBars: [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8]
    property real audioEnergy: 0
    readonly property bool playing: sys.pstat === "Playing" || audioEnergy > 5
    property bool blinking: false

    // Adaptive BPM & Continuous Phase Engine
    property real beatPhase: 0.0
    property real detectedBpm: 76.0      // Raw BPM from onset intervals
    property real smoothBpm: 76.0        // Smoothed BPM driving the feet & head
    property real bassAvg: 15.0          // Rolling low-end energy baseline
    property double lastPeakTime: 0
    property var beatIntervals: []

    // Real-time 60fps Cava Audio Stream + Kick Onset BPM Tracker
    Process {
        id: cavaProc
        command: ["cava", "-p", Quickshell.env("HOME") + "/rice/shell-qs/cava-shellby.conf"]
        running: mascot.visible
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(";")
                if (parts.length >= 16) {
                    let arr = []
                    let sum = 0
                    for (let i = 0; i < 16; i++) {
                        let v = parseInt(parts[i]) || 0
                        sum += v
                        arr.push(Math.max(8, Math.round(v * 0.68)))
                    }
                    mascot.cavaBars = arr
                    const curEnergy = sum / 16.0
                    mascot.audioEnergy = mascot.audioEnergy * 0.85 + curEnergy * 0.15

                    // Kick/Downbeat Onset Detection on Bars 0..2
                    const bassNow = ((parseInt(parts[0]) || 0) + (parseInt(parts[1]) || 0) + (parseInt(parts[2]) || 0)) / 3.0
                    const now = Date.now()
                    const dt = now - mascot.lastPeakTime

                    // Detect sharp transient spike above rolling bass average (min 330ms between beats = max 180 BPM)
                    if (bassNow > mascot.bassAvg * 1.38 && bassNow > 22 && dt > 330) {
                        if (dt < 1600) {
                            let ivs = mascot.beatIntervals.slice()
                            ivs.push(dt)
                            if (ivs.length > 6) ivs.shift()
                            mascot.beatIntervals = ivs

                            // Sort copy to take median interval (rejects syncopated outliers!)
                            let sorted = ivs.slice().sort((a, b) => a - b)
                            let medDt = sorted[Math.floor(sorted.length / 2)]
                            let rawBpm = 60000.0 / medDt

                            // Fold double-time / half-time into natural foot-tapping range (52 - 138 BPM)
                            while (rawBpm > 138) rawBpm *= 0.5
                            while (rawBpm < 52) rawBpm *= 2.0
                            mascot.detectedBpm = rawBpm
                        }
                        mascot.lastPeakTime = now
                    }

                    // If no harsh drum peaks for >2.2s (e.g. soft ballad / piano / strings),
                    // gently glide target BPM down with overall song energy (52 - 78 BPM)
                    if (now - mascot.lastPeakTime > 2200) {
                        mascot.detectedBpm = 52.0 + Math.min(26.0, mascot.audioEnergy * 0.65)
                    }

                    mascot.bassAvg = mascot.bassAvg * 0.90 + bassNow * 0.10
                }
            }
        }
    }

    Timer {
        interval: 3400
        running: true
        repeat: true
        onTriggered: {
            mascot.blinking = true
            blinkReset.start()
        }
    }
    Timer {
        id: blinkReset
        interval: 150
        onTriggered: mascot.blinking = false
    }

    // Continuous 60 FPS Phase Integrator (Advances strictly at smoothBpm!)
    Timer {
        interval: 16
        running: mascot.playing && mascot.visible
        repeat: true
        onTriggered: {
            // Scale tempo slightly down when song is very quiet so ballads feel extra chill
            const energyScale = mascot.audioEnergy < 18 ? 0.78 : 1.0
            const target = Math.max(48.0, Math.min(136.0, mascot.detectedBpm * energyScale))
            mascot.smoothBpm = mascot.smoothBpm * 0.96 + target * 0.04

            // Advance phase: 1 full tap cycle = Math.PI radians in Math.sin()
            const beatsPerSec = mascot.smoothBpm / 60.0
            mascot.beatPhase = (mascot.beatPhase + beatsPerSec * 0.016 * Math.PI) % (Math.PI * 200)
        }
    }

    // 1. Floating Music Notes (Drift upward at the song's tempo!)
    Repeater {
        model: 3
        Text {
            text: index % 2 === 0 ? "♪" : "♫"
            color: index === 1 ? mascot.pal.c13 : mascot.pal.c14
            font.pixelSize: 22
            opacity: mascot.playing ? 0.95 : 0.0
            x: 135 + index * 70 + Math.sin(mascot.beatPhase * 0.7 + index * 2.1) * 14
            y: 10 - (((mascot.beatPhase * 12) + index * 20) % 34)
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }
    }

    // 2. S-Curved Neck Wire Connecting Head to Torso Card
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: mascot.pal.c5
            strokeWidth: 5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 215; startY: 104
            PathCubic {
                x: 215; y: 146
                control1X: 260; control1Y: 116
                control2X: 170; control2Y: 134
            }
        }
    }

    // 3. Shellby's Head (Bobs at the Live Song BPM!)
    Rectangle {
        id: headBox
        width: 146
        height: 78
        radius: 32
        anchors.horizontalCenter: parent.horizontalCenter
        y: mascot.playing ? 28 + Math.sin(mascot.beatPhase * 2.0) * 3.5 : 30
        color: mascot.pal.bg
        border.color: mascot.pal.c5
        border.width: 3

        Rectangle {
            width: 10; height: 26; radius: 5
            color: mascot.pal.c4
            anchors.right: parent.left; anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            width: 10; height: 26; radius: 5
            color: mascot.pal.c4
            anchors.left: parent.right; anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: 22
            color: Qt.darker(mascot.pal.bg, 1.35)
            border.color: mascot.pal.c8
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 28
                Repeater {
                    model: 2
                    Rectangle {
                        width: 18
                        height: mascot.blinking ? 4 : Math.min(28, 18 + mascot.audioEnergy * 0.14)
                        radius: width / 2
                        color: mascot.playing ? mascot.pal.c10 : mascot.pal.c12
                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }
    }

    // 4. Shellby's Torso Card (Track + Artist + Album + Live Cava Belly Visualizer)
    Rectangle {
        id: torso
        width: 400
        height: 248
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 142
        color: mascot.pal.bg
        border.color: mascot.pal.c5
        border.width: 3

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Row {
                width: parent.width
                spacing: 16

                // Album Art / Disc
                Rectangle {
                    width: 92; height: 92; radius: 20
                    color: mascot.pal.c0
                    border.color: mascot.pal.c4
                    border.width: 2
                    clip: true

                    Image {
                        id: coverImg
                        anchors.fill: parent
                        anchors.margins: 2
                        source: mascot.sys.art || ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        text: mascot.playing ? "󰀥" : "󰝚"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 38
                        color: mascot.pal.c5
                        visible: coverImg.status !== Image.Ready
                        rotation: mascot.playing ? (mascot.beatPhase * 45) % 360 : 0
                    }
                }

                // Track, Artist & Album Metadata + Controls
                Column {
                    width: parent.width - 108
                    spacing: 3

                    Text {
                        width: parent.width
                        text: mascot.sys.title || "Nothing Playing"
                        color: mascot.pal.fg
                        font.family: "Orbitron"
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: mascot.sys.artist || "Shellby FM"
                        color: mascot.pal.c12
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: mascot.sys.album
                            ? ("󰀥 " + mascot.sys.album)
                            : (mascot.playing ? ("󰎈 " + Math.round(mascot.smoothBpm) + " BPM Groove") : "󰎈 Standby")
                        color: mascot.pal.c8
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: 16
                        topPadding: 4

                        Repeater {
                            model: [
                                { icon: "󰒮", cmd: "previous" },
                                { icon: mascot.playing ? "󰏤" : "󰐊", cmd: "play-pause" },
                                { icon: "󰒭", cmd: "next" }
                            ]
                            Rectangle {
                                width: 42; height: 30; radius: 9
                                color: btnMouse.containsMouse ? mascot.pal.c5 : mascot.pal.c0
                                border.color: mascot.pal.c8
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: btnMouse.containsMouse ? mascot.pal.bg : mascot.pal.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 17
                                }
                                MouseArea {
                                    id: btnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: Quickshell.execDetached(["playerctl", "-a", modelData.cmd])
                                }
                            }
                        }
                    }
                }
            }

            // LIVE 16-Bar Cava FFT Audio Spectrum Belly
            Rectangle {
                width: parent.width
                height: 86
                radius: 18
                color: Qt.darker(mascot.pal.bg, 1.35)
                border.color: mascot.pal.c8
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: 16
                        Rectangle {
                            width: 12
                            height: mascot.cavaBars[index] || 8
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: index % 3 === 0 ? mascot.pal.c5 : (index % 2 === 0 ? mascot.pal.c4 : mascot.pal.c6)
                            Behavior on height { NumberAnimation { duration: 45 } }
                        }
                    }
                }
            }
        }
    }

    // 5. Left-Facing Tapping Feet (Driven by Adaptive Song BPM!)
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -10
        y: 396
        spacing: 88

        Repeater {
            model: 2
            Rectangle {
                width: 60
                height: 26
                radius: 13
                color: mascot.pal.bg
                border.color: mascot.pal.c5
                border.width: 3
                transformOrigin: Item.Right
                // Smooth lift up, crisp slap down to 0 deg at the exact detected BPM!
                rotation: mascot.playing
                    ? Math.pow(Math.abs(Math.sin(mascot.beatPhase)), 0.6) * (mascot.audioEnergy < 16 ? 11 : 18)
                    : 0

                // Little Toe Cap on the Left Tip of Each Foot
                Rectangle {
                    width: 16
                    height: parent.height - 6
                    radius: 8
                    x: 3
                    anchors.verticalCenter: parent.verticalCenter
                    color: mascot.pal.c5
                    opacity: 0.35
                }
            }
        }
    }
}
