import QtQuick

Item {
    id: escort
    width: 320
    height: 110

    property var pal
    property int currentWs: 1
    property int prevWs: 1
    property int dir: 1               // +1 moving right, -1 moving left
    property real runProgress: 0.0    // 0 -> 1 dash across bottom of screen
    property bool runningDash: false

    visible: runningDash

    function summon(newWs) {
        if (newWs === currentWs) return
        dir = newWs > currentWs ? 1 : -1
        prevWs = currentWs
        currentWs = newWs
        runningDash = true
        dashAnim.restart()
    }

    NumberAnimation {
        id: dashAnim
        target: escort
        property: "runProgress"
        from: 0.0; to: 1.0
        duration: 760
        easing.type: Easing.OutCubic
        onFinished: escort.runningDash = false
    }

    readonly property real slideOffset: (runProgress - 0.5) * 260 * dir
    opacity: Math.sin(runProgress * Math.PI)

    Item {
        anchors.centerIn: parent
        transform: Translate { x: escort.slideOffset }

        // Speed Comet Tail Behind Zippy
        Repeater {
            model: 3
            Rectangle {
                width: 36 - index * 8
                height: 8 - index * 2
                radius: height / 2
                color: index % 2 === 0 ? escort.pal.c5 : escort.pal.c4
                opacity: 0.55 - index * 0.15
                x: escort.dir > 0 ? (-44 - index * 18) : (164 + index * 18)
                y: 16 + index * 10
            }
        }

        // Zippy's Speedy Rocket-Ferret / Courier Body Carrying the Workspace Badge
        Rectangle {
            width: 156
            height: 54
            radius: 27
            color: escort.pal.bg
            border.color: escort.pal.c5
            border.width: 3

            // Swept-Back Aerodynamic Ears
            Rectangle {
                width: 26; height: 12; radius: 6
                color: escort.pal.c5
                x: escort.dir > 0 ? 14 : 116
                y: -8
                rotation: escort.dir > 0 ? -24 : 24
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                layoutDirection: escort.dir > 0 ? Qt.LeftToRight : Qt.RightToLeft

                // Workspace Number Badge
                Rectangle {
                    width: 68; height: 34; radius: 17
                    anchors.verticalCenter: parent.verticalCenter
                    color: escort.pal.c5
                    Text {
                        anchors.centerIn: parent
                        text: "WS 0" + escort.currentWs
                        color: escort.pal.bg
                        font.family: "Orbitron"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                // Zippy's Determined Courier Eyes
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Repeater {
                        model: 2
                        Rectangle {
                            width: 12; height: 16; radius: 6
                            color: escort.pal.c10
                        }
                    }
                }
            }

            // Little Scrambling Paws Underneath
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 48
                spacing: 56
                Repeater {
                    model: 2
                    Rectangle {
                        width: 24; height: 12; radius: 6
                        color: escort.pal.c4
                        rotation: Math.sin(escort.runProgress * 22 + index * 3) * 25
                    }
                }
            }
        }
    }
}
