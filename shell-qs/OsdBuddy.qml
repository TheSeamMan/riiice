import QtQuick

Item {
    id: peep
    width: 280
    height: 118
    visible: true
    opacity: active ? 1.0 : 0.0
    enabled: active

    Behavior on opacity {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }

    property var pal
    property bool active: false
    property string mode: "vol"
    property int val: 50
    property real popScale: active ? 1.0 : 0.82

    Behavior on popScale {
        NumberAnimation { duration: 160; easing.type: Easing.OutBack }
    }

    transform: Scale {
        origin.x: peep.width / 2
        origin.y: peep.height / 2
        xScale: peep.popScale
        yScale: peep.popScale
    }

    function trigger(m, v) {
        peep.mode = m
        peep.val = Math.max(0, Math.min(150, Math.round(Number(v) || 0)))
        peep.active = true
        hideTimer.stop()
        hideTimer.start()
    }

    Timer {
        id: hideTimer
        interval: 1350
        repeat: false
        onTriggered: peep.active = false
    }

    # Peep's Antenna Ears
    Repeater {
        model: [-1, 1]
        Rectangle {
            width: 18; height: 28; radius: 9
            color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
            border.color: peep.pal.fg; border.width: 2
            x: (peep.width / 2) + (modelData * 48) - width / 2
            y: 4
            rotation: modelData * (10 + (peep.val * 0.12))
        }
    }

    # Peep's Goggle Visor Head
    Rectangle {
        width: 112; height: 42; radius: 21
        anchors.horizontalCenter: parent.horizontalCenter
        y: 12
        color: peep.pal.bg
        border.color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
        border.width: 3

        Row {
            anchors.centerIn: parent
            spacing: 20
            Repeater {
                model: 2
                Rectangle {
                    width: 18
                    height: Math.max(6, Math.min(22, 8 + (peep.val / 100.0) * 14))
                    radius: width / 2
                    color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: peep.pal.bg
                        anchors.top: parent.top; anchors.topMargin: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    # Peep's Pill Body
    Rectangle {
        width: 268; height: 58; radius: 29
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48
        color: peep.pal.bg
        border.color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
        border.width: 3

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18; anchors.rightMargin: 18
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (peep.mode === "bri") return "󰌵"
                    if (peep.val === 0) return "󰝟"
                    if (peep.val < 40) return "󰕿"
                    if (peep.val < 80) return "󰖀"
                    return "󰕾"
                }
                color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
            }

            Rectangle {
                width: 138; height: 14; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.darker(peep.pal.bg, 1.45)
                border.color: peep.pal.c0; border.width: 1

                Rectangle {
                    width: parent.width * Math.max(0.0, Math.min(1.0, peep.val / 100.0))
                    height: parent.height; radius: 7
                    color: peep.mode === "bri" ? peep.pal.c11 : peep.pal.c6
                    Behavior on width { NumberAnimation { duration: 50 } }
                }
            }

            Text {
                width: 52
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: peep.val + "%"
                color: peep.pal.fg
                font.family: "DSEG7 Classic"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
