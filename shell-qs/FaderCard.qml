import QtQuick
import Quickshell

Item {
    id: fader
    width: 396
    height: 375

    property var pal
    property var sys: ({
        vol: 50, mute: "false", mic: 80, micon: true, micmute: "false", bri: 80
    })

    property int localVol: 50
    property int localMic: 80
    property int localBri: 80
    property bool draggingVol: false
    property bool draggingMic: false
    property bool draggingBri: false
    property real beatPhase: 0

    // Top-level helpers called by shell.qml onWheel (takes target percentage!)
    function applyVol(targetVal) {
        const v = Math.max(0, Math.min(150, Math.round(targetVal)))
        fader.localVol = v
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", v + "%"])
    }
    function applyMic(targetVal) {
        const v = Math.max(0, Math.min(100, Math.round(targetVal)))
        fader.localMic = v
        Quickshell.execDetached(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", v + "%"])
    }
    function applyBri(targetVal) {
        const v = Math.max(5, Math.min(100, Math.round(targetVal)))
        fader.localBri = v
        Quickshell.execDetached(["brightnessctl", "set", v + "%"])
    }

    onSysChanged: {
        if (!draggingVol && sys.vol !== undefined) localVol = Number(sys.vol)
        if (!draggingMic && sys.mic !== undefined) localMic = Number(sys.mic)
        if (!draggingBri && sys.bri !== undefined) localBri = Number(sys.bri)
    }

    Timer {
        interval: 60
        running: fader.visible
        repeat: true
        onTriggered: fader.beatPhase = (fader.beatPhase + 1) % 360
    }

    // 1. Crooked DJ Headphone Arc Over Fader's Head
    Rectangle {
        width: 196; height: 74; radius: 37
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12
        color: "transparent"
        border.color: fader.pal.c6
        border.width: 5
    }

    // 2. DJ Ear Cups
    Rectangle {
        width: 48; height: 34; radius: 12
        color: fader.pal.c5
        border.color: fader.pal.fg; border.width: 2
        x: 78; y: 36
        transformOrigin: Item.Right
        rotation: -18 + Math.sin(fader.beatPhase * 0.35) * 10
    }
    Rectangle {
        width: 48; height: 34; radius: 12
        color: fader.pal.c5
        border.color: fader.pal.fg; border.width: 2
        x: 270; y: 36
        transformOrigin: Item.Left
        rotation: 18 - Math.sin(fader.beatPhase * 0.35) * 10
    }

    // 3. Fader's Wide DJ Boombox Head (With 7-Bar Graphic Equalizer Visor!)
    Rectangle {
        width: 166; height: 64; radius: 18
        anchors.horizontalCenter: parent.horizontalCenter
        y: 28
        color: fader.pal.bg
        border.color: fader.pal.c6
        border.width: 3

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 9
            radius: 11
            color: Qt.darker(fader.pal.bg, 1.55)
            border.color: fader.pal.c0; border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: [0.45, 0.8, 1.0, 0.65, 0.95, 0.75, 0.45]
                    Rectangle {
                        width: 10
                        height: Math.max(6, Math.min(34, (fader.localVol * 0.30 + 6) * modelData + Math.sin(fader.beatPhase * 0.4 + index) * 4))
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: index % 2 === 0 ? fader.pal.c6 : fader.pal.c11
                        Behavior on height { NumberAnimation { duration: 55 } }
                    }
                }
            }
        }
    }

    // 4. Fader's Mixer Deck Torso (3 Sliders + Quick Mute/Media Transport)
    Rectangle {
        width: 372
        height: 248
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 94
        color: fader.pal.bg
        border.color: fader.pal.c6
        border.width: 3

        MouseArea { anchors.fill: parent; z: -1 }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            Row {
                width: parent.width
                Text {
                    width: parent.width * 0.65
                    text: "FADER // STUDIO AUDIO & LIGHT"
                    color: fader.pal.c6
                    font.family: "Orbitron"
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    width: parent.width * 0.35
                    horizontalAlignment: Text.AlignRight
                    text: fader.sys.mute === "true" ? "󰝟 MUTED" : "󰕾 LIVE"
                    color: fader.sys.mute === "true" ? fader.pal.c1 : fader.pal.c10
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            // A. Speaker Volume Slider
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        width: parent.width * 0.7
                        text: (fader.sys.mute === "true" ? "󰝟 " : "󰕾 ") + "Speaker Output"
                        color: fader.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11; font.bold: true
                    }
                    Text {
                        width: parent.width * 0.3
                        horizontalAlignment: Text.AlignRight
                        text: fader.localVol + "%"
                        color: fader.pal.c6
                        font.family: "DSEG7 Classic"; font.pixelSize: 11
                    }
                }
                Rectangle {
                    width: parent.width; height: 14; radius: 7
                    color: Qt.darker(fader.pal.bg, 1.45)
                    border.color: fader.pal.c0; border.width: 1
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, fader.localVol / 100.0))
                        height: parent.height; radius: 7
                        color: fader.sys.mute === "true" ? fader.pal.c8 : fader.pal.c6
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => {
                            fader.draggingVol = true
                            fader.applyVol((mouse.x / width) * 100)
                        }
                        onPositionChanged: mouse => {
                            if (pressed) fader.applyVol((mouse.x / width) * 100)
                        }
                        onReleased: fader.draggingVol = false
                        onWheel: wheel => {
                            const step = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 5 : -5
                            fader.applyVol(fader.localVol + step)
                        }
                    }
                }
            }

            // B. Studio Mic Gain Slider
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        width: parent.width * 0.7
                        text: (!fader.sys.micon || fader.sys.micmute === "true" ? "󰍭 " : "󰍬 ") + "Fifine Studio Mic"
                        color: fader.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11; font.bold: true
                    }
                    Text {
                        width: parent.width * 0.3
                        horizontalAlignment: Text.AlignRight
                        text: fader.localMic + "%"
                        color: fader.pal.c4
                        font.family: "DSEG7 Classic"; font.pixelSize: 11
                    }
                }
                Rectangle {
                    width: parent.width; height: 14; radius: 7
                    color: Qt.darker(fader.pal.bg, 1.45)
                    border.color: fader.pal.c0; border.width: 1
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, fader.localMic / 100.0))
                        height: parent.height; radius: 7
                        color: (!fader.sys.micon || fader.sys.micmute === "true") ? fader.pal.c1 : fader.pal.c4
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => {
                            fader.draggingMic = true
                            fader.applyMic((mouse.x / width) * 100)
                        }
                        onPositionChanged: mouse => {
                            if (pressed) fader.applyMic((mouse.x / width) * 100)
                        }
                        onReleased: fader.draggingMic = false
                        onWheel: wheel => {
                            const step = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 5 : -5
                            fader.applyMic(fader.localMic + step)
                        }
                    }
                }
            }

            // C. Panel Backlight Slider
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        width: parent.width * 0.7
                        text: "󰌵 Display Backlight"
                        color: fader.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11; font.bold: true
                    }
                    Text {
                        width: parent.width * 0.3
                        horizontalAlignment: Text.AlignRight
                        text: fader.localBri + "%"
                        color: fader.pal.c11
                        font.family: "DSEG7 Classic"; font.pixelSize: 11
                    }
                }
                Rectangle {
                    width: parent.width; height: 14; radius: 7
                    color: Qt.darker(fader.pal.bg, 1.45)
                    border.color: fader.pal.c0; border.width: 1
                    Rectangle {
                        width: parent.width * Math.max(0.05, Math.min(1, fader.localBri / 100.0))
                        height: parent.height; radius: 7
                        color: fader.pal.c11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => {
                            fader.draggingBri = true
                            fader.applyBri((mouse.x / width) * 100)
                        }
                        onPositionChanged: mouse => {
                            if (pressed) fader.applyBri((mouse.x / width) * 100)
                        }
                        onReleased: fader.draggingBri = false
                        onWheel: wheel => {
                            const step = (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) ? 5 : -5
                            fader.applyBri(fader.localBri + step)
                        }
                    }
                }
            }

            // D. Quick Mute & Media Transport Buttons
            Row {
                width: parent.width
                spacing: 6

                Rectangle {
                    width: (parent.width - 18) * 0.34; height: 28; radius: 8
                    color: fader.sys.mute === "true" ? fader.pal.c1 : fader.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: fader.sys.mute === "true" ? "󰝟 UNMUTE" : "󰕾 MUTE"
                        color: fader.sys.mute === "true" ? fader.pal.bg : fader.pal.fg
                        font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                    }
                }

                Rectangle {
                    width: (parent.width - 18) * 0.34; height: 28; radius: 8
                    color: (!fader.sys.micon || fader.sys.micmute === "true") ? fader.pal.c1 : fader.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: (!fader.sys.micon || fader.sys.micmute === "true") ? "󰍭 MIC OFF" : "󰍬 MIC ON"
                        color: (!fader.sys.micon || fader.sys.micmute === "true") ? fader.pal.bg : fader.pal.c10
                        font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
                    }
                }

                Rectangle {
                    width: (parent.width - 18) * 0.16; height: 28; radius: 8
                    color: fader.pal.c0
                    Text { anchors.centerIn: parent; text: "󰒮"; color: fader.pal.fg; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "previous"]) }
                }

                Rectangle {
                    width: (parent.width - 18) * 0.16; height: 28; radius: 8
                    color: fader.pal.c0
                    Text { anchors.centerIn: parent; text: "󰒭"; color: fader.pal.fg; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["playerctl", "next"]) }
                }
            }
        }
    }

    // 5. Little Subwoofer Feet Underneath
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 346
        spacing: 110
        Repeater {
            model: 2
            Rectangle {
                width: 48; height: 18; radius: 9
                color: fader.pal.bg
                border.color: fader.pal.c6
                border.width: 3
            }
        }
    }
}
