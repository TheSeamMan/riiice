import QtQuick
import Quickshell

Item {
    id: juice
    width: 356
    height: 350

    property var pal
    property var sys: ({
        bat: 100, bat_stat: "Charging", bat_watt: "0.0", pwr_mode: "balanced"
    })

    property real bubblePhase: 0
    property string localMode: sys.pwr_mode || "balanced"

    onSysChanged: {
        if (sys.pwr_mode) localMode = sys.pwr_mode
    }

    Timer {
        interval: 65
        running: juice.visible
        repeat: true
        onTriggered: juice.bubblePhase = (juice.bubblePhase + 1) % 360
    }

    readonly property int batPct: Number(sys.bat !== undefined ? sys.bat : 100)
    readonly property bool isCharging: (sys.bat_stat === "Charging" || sys.bat_stat === "Full" || sys.bat_stat === "Not charging" || sys.bat_stat === "Plugged")
    readonly property color juiceCol: {
        if (localMode === "performance") return juice.pal.c1
        if (localMode === "saver") return juice.pal.c10
        if (batPct <= 20 && !isCharging) return juice.pal.c1
        return juice.pal.c11
    }

    // 1. Positive Brass Battery Terminal Cap on Top of Juice's Head
    Rectangle {
        width: 54; height: 18; radius: 6
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        color: juice.juiceCol
        border.color: juice.pal.fg; border.width: 2

        Text {
            anchors.centerIn: parent
            text: isCharging ? "⚡ + ⚡" : "+ CELL +"
            color: juice.pal.bg
            font.family: "Orbitron"; font.pixelSize: 8; font.bold: true
        }
    }

    // 2. Twin Tesla Coil Side Insulators (Crackling when charging/turbo!)
    Repeater {
        model: [-1, 1]
        Rectangle {
            width: 24; height: 34; radius: 8
            color: juice.pal.c0
            border.color: juice.juiceCol; border.width: 2
            x: modelData === -1 ? 82 : 250
            y: 38
            rotation: modelData * (12 + Math.sin(juice.bubblePhase * 0.35) * (juice.isCharging ? 8 : 2))
            Text {
                anchors.centerIn: parent
                text: "󱐋"
                color: juice.juiceCol
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14
            }
        }
    }

    // 3. Juice's Translucent Electrolyte Tank Head (With Rising Liquid Charge Level!)
    Rectangle {
        width: 142; height: 70; radius: 18
        anchors.horizontalCenter: parent.horizontalCenter
        y: 22
        color: Qt.darker(juice.pal.bg, 1.4)
        border.color: juice.juiceCol
        border.width: 3
        clip: true

        MouseArea { anchors.fill: parent }

        // Liquid Electrolyte Fill Inside Head
        Rectangle {
            width: parent.width - 12
            height: Math.max(10, (parent.height - 12) * (juice.batPct / 100.0))
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            radius: 12
            color: Qt.rgba(juice.juiceCol.r, juice.juiceCol.g, juice.juiceCol.b, 0.38)
            border.color: juice.juiceCol; border.width: 1
        }

        // Glowing Eyes Floating in the Electrolyte
        Row {
            anchors.centerIn: parent
            spacing: 26
            Repeater {
                model: 2
                Rectangle {
                    width: 20; height: 22; radius: 10
                    color: juice.juiceCol
                    border.color: juice.pal.fg; border.width: 1.5
                    Rectangle {
                        width: 7; height: 7; radius: 3.5
                        color: juice.pal.bg
                        x: 6 + Math.cos(juice.bubblePhase * 0.2) * 3
                        y: 6 + Math.sin(juice.bubblePhase * 0.2) * 3
                    }
                }
            }
        }
    }

    // 4. Juice's Power Reactor Torso
    Rectangle {
        width: 334
        height: 224
        radius: 26
        anchors.horizontalCenter: parent.horizontalCenter
        y: 94
        color: juice.pal.bg
        border.color: juice.juiceCol
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
                    width: parent.width * 0.62
                    text: "JUICE // POWER & BATTERY"
                    color: juice.juiceCol
                    font.family: "Orbitron"; font.pixelSize: 11; font.bold: true
                }
                Text {
                    width: parent.width * 0.38
                    horizontalAlignment: Text.AlignRight
                    text: (juice.sys.bat_stat || "AC").toUpperCase()
                    color: juice.isCharging ? juice.pal.c10 : juice.pal.c11
                    font.family: "Orbitron"; font.pixelSize: 10; font.bold: true
                }
            }

            // Big Segmented Battery Bar + Digital Readout
            Rectangle {
                width: parent.width; height: 54; radius: 14
                color: Qt.darker(juice.pal.bg, 1.45)
                border.color: juice.pal.c0; border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Text {
                        width: 92
                        anchors.verticalCenter: parent.verticalCenter
                        text: juice.batPct + "%"
                        color: juice.juiceCol
                        font.family: "DSEG7 Classic"
                        font.pixelSize: 24; font.bold: true
                    }

                    Column {
                        width: parent.width - 104
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        // 10-cell battery bar
                        Row {
                            spacing: 4
                            Repeater {
                                model: 10
                                Rectangle {
                                    width: 16; height: 14; radius: 3
                                    color: (index * 10) < juice.batPct ? juice.juiceCol : juice.pal.c0
                                }
                            }
                        }

                        Text {
                            text: "Draw: " + (juice.sys.bat_watt || "0.0") + " W  •  Profile: " + juice.localMode.toUpperCase()
                            color: juice.pal.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // 3-Way Power Mode Switcher (Saver / Balanced / Turbo)
            Column {
                width: parent.width
                spacing: 5

                Text {
                    text: "󰓅  MSI RAIDER CPU & THERMAL GOVERNOR"
                    color: juice.pal.c13
                    font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "saver",       label: "🍃 SAVER",    sub: "2.4 GHz Quiet", col: "c10" },
                            { id: "balanced",    label: "⚖️ BALANCED", sub: "3.4 GHz Cool",  col: "c11" },
                            { id: "performance", label: "⚡ TURBO",    sub: "5.0 GHz Max",   col: "c1"  }
                        ]
                        Rectangle {
                            readonly property bool isCur: juice.localMode === modelData.id
                            readonly property color mCol: juice.pal[modelData.col] || juice.pal.c11
                            width: (parent.width - 16) / 3
                            height: 46; radius: 10
                            color: isCur ? mCol : juice.pal.c0
                            border.color: mCol; border.width: 1.5

                            Column {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: isCur ? juice.pal.bg : juice.pal.fg
                                    font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.sub
                                    color: isCur ? juice.pal.bg : juice.pal.c7
                                    font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 8
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    juice.localMode = modelData.id
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/rice/scripts/power-mode", modelData.id])
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 5. Heavy Grounding Boots
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 320
        spacing: 96
        Repeater {
            model: 2
            Rectangle {
                width: 44; height: 16; radius: 8
                color: juice.pal.bg
                border.color: juice.juiceCol; border.width: 3
            }
        }
    }
}
