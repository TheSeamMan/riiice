import QtQuick
import QtQuick.Shapes

Item {
    id: boiler
    width: 440
    height: 440

    property var pal
    property var sys: ({
        cpu: 0, ram: 0, gpu: 0, gputemp: 0, gpumem: 0, bat: 100, batstat: "AC"
    })

    property real steamPhase: 0
    property real fillFactor: 0.0
    property real tapeUnroll: 0.0

    onVisibleChanged: {
        if (visible) {
            fillFactor = 0.0
            tapeUnroll = 0.0
            fillUpAnim.restart()
            tapeAnim.restart()
        }
    }

    NumberAnimation {
        id: fillUpAnim
        target: boiler
        property: "fillFactor"
        from: 0.0; to: 1.0
        duration: 850
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: tapeAnim
        target: boiler
        property: "tapeUnroll"
        from: 0.0; to: 1.0
        duration: 1100
        easing.type: Easing.OutBack
    }

    Timer {
        interval: 80
        running: boiler.visible
        repeat: true
        onTriggered: boiler.steamPhase = (boiler.steamPhase + 1) % 200
    }

    // 1. Dual Brass Smokestacks & Rising Steam Puffs
    Repeater {
        model: 4
        Rectangle {
            readonly property real cycle: ((boiler.steamPhase * 1.5 + index * 25) % 100) / 100
            width: 14 + cycle * 24
            height: width
            radius: width / 2
            color: (boiler.sys.gputemp || 0) > 70 ? boiler.pal.c1 : boiler.pal.c14
            opacity: (1.0 - cycle) * 0.65
            x: (index % 2 === 0 ? 175 : 235) - width / 2 + Math.sin(cycle * 6 + index) * 10
            y: 26 - cycle * 30
        }
    }

    // Left & Right Brass Chimneys
    Rectangle {
        width: 22; height: 24; radius: 5
        x: 164; y: 18; rotation: -8
        color: boiler.pal.c0; border.color: boiler.pal.c14; border.width: 3
    }
    Rectangle {
        width: 22; height: 24; radius: 5
        x: 224; y: 18; rotation: 8
        color: boiler.pal.c0; border.color: boiler.pal.c14; border.width: 3
    }

    // 2. Fluttering Dot-Matrix Ticker-Tape Ribbon Coming Out of Her Head!
    Item {
        id: tickerSlot
        x: 294; y: 46
        width: 135; height: 70
        transformOrigin: Item.Left
        scale: boiler.tapeUnroll
        rotation: Math.sin(boiler.steamPhase * 0.22) * 6

        // Brass Printer Slot Mouth on Side of Head
        Rectangle {
            x: -6; y: 12
            width: 10; height: 28; radius: 3
            color: boiler.pal.c3
            border.color: boiler.pal.bg; border.width: 2
        }

        // Curling Perforated Paper Strip
        Rectangle {
            x: 2; y: 14
            width: 122 * boiler.tapeUnroll
            height: 26
            radius: 4
            color: "#f8f4e6"
            border.color: boiler.pal.c8
            border.width: 1.5
            rotation: 4 + Math.cos(boiler.steamPhase * 0.28) * 5

            // Tractor-Feed Perforation Dots Along Top & Bottom Edges
            Row {
                anchors.top: parent.top; anchors.topMargin: 2
                anchors.left: parent.left; anchors.leftMargin: 4
                spacing: 6
                Repeater {
                    model: 12
                    Rectangle { width: 3; height: 3; radius: 1.5; color: "#888477" }
                }
            }
            Row {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                anchors.left: parent.left; anchors.leftMargin: 4
                spacing: 6
                Repeater {
                    model: 12
                    Rectangle { width: 3; height: 3; radius: 1.5; color: "#888477" }
                }
            }

            // Live Printed Dot-Matrix Readout on the Paper
            Text {
                anchors.centerIn: parent
                text: "CPU:" + (boiler.sys.cpu || 0) + "% RTX:" + (boiler.sys.gputemp || 0) + "C"
                color: "#1b1e28"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
            }
        }
    }

    // 3. Boiler's Wide Industrial Dome Head (With Eyelashes & Rosy Furnace Cheeks!)
    Rectangle {
        width: 196; height: 68; radius: 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -10
        y: 36
        color: boiler.pal.bg
        border.color: boiler.pal.c14
        border.width: 3

        // Rosy Warm Furnace Cheeks
        Rectangle {
            width: 18; height: 10; radius: 5
            x: 10; y: 44
            color: boiler.pal.c1; opacity: 0.55
        }
        Rectangle {
            width: 18; height: 10; radius: 5
            x: 168; y: 44
            color: boiler.pal.c1; opacity: 0.55
        }

        // Three Pressure-Gauge Eyes with Cute Mechanical Eyelashes!
        Row {
            anchors.centerIn: parent
            spacing: 14
            Repeater {
                model: [
                    { val: Number(boiler.sys.cpu || 0), col: boiler.pal.c4 },
                    { val: Number(boiler.sys.ram || 0), col: boiler.pal.c14 },
                    { val: Number(boiler.sys.gpu || 0), col: boiler.pal.c2 }
                ]
                Item {
                    width: 38; height: 42

                    // 3 Little Mechanical Eyelashes Above Each Gauge Eye
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 3; height: 7; radius: 1.5
                            color: boiler.pal.c14
                            x: 10 + index * 8
                            y: -2
                            rotation: (index - 1) * 22
                        }
                    }

                    Rectangle {
                        y: 4
                        width: 36; height: 36; radius: 18
                        color: Qt.darker(boiler.pal.bg, 1.4)
                        border.color: modelData.col
                        border.width: 2

                        Rectangle {
                            width: 3; height: 14; radius: 1.5
                            color: boiler.pal.fg
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 4
                            transformOrigin: Item.Bottom
                            rotation: -110 + (modelData.val * boiler.fillFactor / 100) * 220 + Math.sin(boiler.steamPhase * 0.4 + index) * 3
                            Behavior on rotation { NumberAnimation { duration: 160 } }
                        }
                    }
                }
            }
        }
    }

    // 4. Boiler's Furnace Belly
    Rectangle {
        width: 376
        height: 284
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -10
        y: 108
        color: boiler.pal.bg
        border.color: boiler.pal.c14
        border.width: 3

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 11

            Row {
                width: parent.width
                height: 18
                Text {
                    width: parent.width * 0.62
                    text: "BOILER // MSI RAIDER MATRIX"
                    color: boiler.pal.c14
                    font.family: "Orbitron"
                    font.pixelSize: 11
                    font.bold: true
                }
                Text {
                    width: parent.width * 0.38
                    horizontalAlignment: Text.AlignRight
                    text: "PWR: " + (boiler.sys.bat || 100) + "% (" + (boiler.sys.batstat || "AC") + ")"
                    color: boiler.pal.c10
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }

            Repeater {
                model: [
                    { name: "CPU LOAD",  val: Number(boiler.sys.cpu || 0),     txt: (boiler.sys.cpu || 0) + "%",      col: boiler.pal.c4 },
                    { name: "MEM USED",  val: Number(boiler.sys.ram || 0),     txt: (boiler.sys.ram || 0) + "%",      col: boiler.pal.c5 },
                    { name: "RTX CORE",  val: Number(boiler.sys.gpu || 0),     txt: (boiler.sys.gpu || 0) + "%",      col: boiler.pal.c2 },
                    { name: "RTX VRAM",  val: Number(boiler.sys.gpumem || 0),  txt: (boiler.sys.gpumem || 0) + "%",   col: boiler.pal.c13 },
                    { name: "RTX TEMP",  val: Number(boiler.sys.gputemp || 0), txt: (boiler.sys.gputemp || 0) + "°C", col: Number(boiler.sys.gputemp || 0) > 75 ? boiler.pal.c1 : boiler.pal.c11 }
                ]
                Column {
                    id: metricRow
                    width: parent.width
                    spacing: 4
                    readonly property int rowIdx: index
                    readonly property real targetVal: Math.max(4, modelData.val * boiler.fillFactor)
                    readonly property color barColor: modelData.col
                    readonly property string barName: modelData.name
                    readonly property string barTxt: modelData.txt

                    Row {
                        width: parent.width
                        Text {
                            width: parent.width * 0.55
                            text: metricRow.barName
                            color: boiler.pal.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            width: parent.width * 0.45
                            horizontalAlignment: Text.AlignRight
                            text: metricRow.barTxt
                            color: metricRow.barColor
                            font.family: "DSEG7 Classic"
                            font.pixelSize: 11
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 3
                        Repeater {
                            model: 24
                            Rectangle {
                                readonly property real segThreshold: (index / 24.0) * 100.0
                                readonly property bool lit: segThreshold < metricRow.targetVal
                                readonly property bool isPeakSegment: lit && ((index + 1) / 24.0) * 100.0 >= metricRow.targetVal
                                readonly property bool shimmerMatch: ((boiler.steamPhase + metricRow.rowIdx * 5) % 24) === index

                                width: (parent.width - 23 * 3) / 24
                                height: 11
                                radius: 2
                                color: lit
                                    ? (shimmerMatch ? boiler.pal.fg : metricRow.barColor)
                                    : Qt.darker(boiler.pal.bg, 1.45)
                                opacity: lit
                                    ? (isPeakSegment ? (boiler.steamPhase % 4 < 2 ? 1.0 : 0.35) : 0.95)
                                    : 0.35
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                        }
                    }
                }
            }
        }
    }

    // 5. Sturdy Boiler Treads Underneath
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -10
        y: 396
        spacing: 118
        Repeater {
            model: 2
            Rectangle {
                width: 64; height: 22; radius: 8
                color: boiler.pal.c0
                border.color: boiler.pal.c14
                border.width: 3
            }
        }
    }
}
