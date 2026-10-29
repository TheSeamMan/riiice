import QtQuick
import Quickshell

Rectangle {
    id: sysCard
    width: 340
    height: 290
    radius: 24
    color: pal.bg
    border.color: pal.c4
    border.width: 3

    property var pal
    property var sys: ({
        cpu: 0, ram: 0, gpu: 0, gputemp: 0,
        vol: 50, micon: true, bat: 100, batstat: "AC", ssid: "Online"
    })

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Text {
            text: "MSI RAIDER TELEMETRY & STUDIO"
            color: sysCard.pal.c5
            font.family: "Orbitron"
            font.pixelSize: 13
            font.bold: true
        }

        // Telemetry Bars (CPU, RAM, NVIDIA GPU)
        Repeater {
            model: [
                { label: "CPU", val: sysCard.sys.cpu || 0, suffix: "%", col: sysCard.pal.c4 },
                { label: "RAM", val: sysCard.sys.ram || 0, suffix: "%", col: sysCard.pal.c5 },
                { label: "RTX", val: sysCard.sys.gpu || 0, suffix: "% (" + (sysCard.sys.gputemp || 0) + "°C)", col: sysCard.pal.c2 }
            ]
            Column {
                width: parent.width
                spacing: 4
                Row {
                    width: parent.width
                    Text {
                        width: parent.width * 0.5
                        text: modelData.label
                        color: sysCard.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Text {
                        width: parent.width * 0.5
                        horizontalAlignment: Text.AlignRight
                        text: modelData.val + modelData.suffix
                        color: sysCard.pal.c8
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
                Rectangle {
                    width: parent.width
                    height: 10
                    radius: 5
                    color: Qt.darker(sysCard.pal.bg, 1.4)
                    Rectangle {
                        width: parent.width * Math.min(1, Math.max(0.04, modelData.val / 100))
                        height: parent.height
                        radius: 5
                        color: modelData.col
                        Behavior on width { NumberAnimation { duration: 250 } }
                    }
                }
            }
        }

        // Output Volume Control
        Column {
            width: parent.width
            spacing: 4
            Row {
                width: parent.width
                Text {
                    width: parent.width * 0.6
                    text: "󰕾  Output Volume"
                    color: sysCard.pal.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
                Text {
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                    text: (sysCard.sys.vol || 0) + "%"
                    color: sysCard.pal.c8
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
            }
            Rectangle {
                width: parent.width
                height: 14
                radius: 7
                color: Qt.darker(sysCard.pal.bg, 1.4)
                Rectangle {
                    width: parent.width * Math.min(1, (sysCard.sys.vol || 0) / 100)
                    height: parent.height
                    radius: 7
                    color: sysCard.pal.c6
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        const pct = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", pct + "%"])
                    }
                }
            }
        }

        // Fifine RNNoise Studio Mic Quick Toggle + Pavucontrol Button
        Row {
            width: parent.width
            spacing: 10

            Rectangle {
                width: (parent.width - 10) * 0.65
                height: 36
                radius: 10
                color: sysCard.sys.micon ? sysCard.pal.c2 : sysCard.pal.c1
                Text {
                    anchors.centerIn: parent
                    text: sysCard.sys.micon ? "󰍬 Fifine ON (RNNoise)" : "󰍭 Fifine MUTED"
                    color: sysCard.pal.bg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
                }
            }

            Rectangle {
                width: (parent.width - 10) * 0.35
                height: 36
                radius: 10
                color: sysCard.pal.c0
                border.color: sysCard.pal.c8
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "󰓃 Mixer"
                    color: sysCard.pal.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["pavucontrol"])
                }
            }
        }
    }
}
