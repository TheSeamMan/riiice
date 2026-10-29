import QtQuick
import Quickshell

Item {
    id: launcher
    width: 500
    height: 480

    property var pal
    property var allApps: []
    property string query: ""
    property real gillWiggle: 0
    signal requestClose()

    function focusSearch() {
        query = ""
        searchInput.text = ""
        filterApps()
        searchInput.forceActiveFocus()
    }

    function filterApps() {
        filteredModel.clear()
        const q = query.trim().toLowerCase()
        for (let i = 0; i < allApps.length; i++) {
            const app = allApps[i]
            if (q === "" || app.name.toLowerCase().includes(q) || app.exec.toLowerCase().includes(q)) {
                filteredModel.append(app)
                if (filteredModel.count >= 50) break
            }
        }
        appList.currentIndex = filteredModel.count > 0 ? 0 : -1
    }

    function launchSelected() {
        if (appList.currentIndex < 0 || appList.currentIndex >= filteredModel.count) return
        const cmd = filteredModel.get(appList.currentIndex).exec
        Quickshell.execDetached(["sh", "-c", "setsid " + cmd + " >/dev/null 2>&1 &"])
        launcher.requestClose()
    }

    onAllAppsChanged: filterApps()

    ListModel { id: filteredModel }

    // 1. Pounce's Frilly Axolotl Gills (Wiggle as You Type or Scroll!)
    Repeater {
        model: 3
        Rectangle {
            width: 38; height: 13; radius: 6.5
            color: index % 2 === 0 ? launcher.pal.c13 : launcher.pal.c6
            x: 52 - (index === 1 ? 10 : 0)
            y: 26 + index * 18
            transformOrigin: Item.Right
            rotation: -18 + index * 16 + Math.sin(launcher.gillWiggle + index) * 15
            Behavior on rotation { NumberAnimation { duration: 90 } }
        }
    }
    Repeater {
        model: 3
        Rectangle {
            width: 38; height: 13; radius: 6.5
            color: index % 2 === 0 ? launcher.pal.c13 : launcher.pal.c6
            x: 410 + (index === 1 ? 10 : 0)
            y: 26 + index * 18
            transformOrigin: Item.Left
            rotation: 18 - index * 16 - Math.sin(launcher.gillWiggle + index) * 15
            Behavior on rotation { NumberAnimation { duration: 90 } }
        }
    }

    // 2. Pounce's Wide Amphibian Head + Mouth Search Bar
    Rectangle {
        id: head
        width: 350
        height: 110
        radius: 38
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        color: launcher.pal.bg
        border.color: launcher.pal.c13
        border.width: 3

        // Big Goggle Eyes on Top of Head
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            spacing: 82
            Repeater {
                model: 2
                Rectangle {
                    width: 40; height: 32; radius: 16
                    color: Qt.darker(launcher.pal.bg, 1.4)
                    border.color: launcher.pal.c13
                    border.width: 2

                    Rectangle {
                        width: 14; height: 16; radius: 7
                        color: launcher.pal.c11
                        x: Math.min(22, 6 + launcher.query.length * 1.6)
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on x { NumberAnimation { duration: 80 } }
                    }
                }
            }
        }

        // Wide Mouth = The Search Input Bar
        Rectangle {
            width: parent.width - 30
            height: 46
            radius: 23
            anchors.horizontalCenter: parent.horizontalCenter
            y: 52
            color: Qt.darker(launcher.pal.bg, 1.45)
            border.color: launcher.pal.c6
            border.width: 2

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    color: launcher.pal.c13
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 90
                    anchors.verticalCenter: parent.verticalCenter
                    color: launcher.pal.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                    clip: true
                    onTextChanged: {
                        launcher.query = text
                        launcher.gillWiggle += 1.6
                        launcher.filterApps()
                    }
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            if (appList.currentIndex < filteredModel.count - 1) appList.currentIndex++
                            launcher.gillWiggle += 0.8
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            if (appList.currentIndex > 0) appList.currentIndex--
                            launcher.gillWiggle += 0.8
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            launcher.launchSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            launcher.requestClose()
                            event.accepted = true
                        }
                    }
                }

                // Live Match Counter Pill inside Mouth
                Rectangle {
                    width: 48; height: 24; radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: launcher.pal.c0
                    border.color: launcher.pal.c13
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: filteredModel.count > 0 ? (appList.currentIndex + 1) + "/" + filteredModel.count : "0/0"
                        color: launcher.pal.c13
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
        }
    }

    // 3. Pounce's Belly Deck (Rich App Cards + Custom Neon Scrollbar)
    Rectangle {
        width: 450
        height: 316
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 124
        color: launcher.pal.bg
        border.color: launcher.pal.c13
        border.width: 3

        // Top HUD Header Strip
        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 18

            Text {
                width: parent.width * 0.6
                text: "POUNCE // APPLICATION MATRIX"
                color: launcher.pal.c13
                font.family: "Orbitron"
                font.pixelSize: 11
                font.bold: true
            }
            Text {
                width: parent.width * 0.4
                horizontalAlignment: Text.AlignRight
                text: "↑↓ NAV   ⏎ LAUNCH"
                color: launcher.pal.c8
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
            }
        }

        ListView {
            id: appList
            anchors.fill: parent
            anchors.topMargin: 42
            anchors.bottomMargin: 16
            anchors.leftMargin: 16
            anchors.rightMargin: 28
            clip: true
            model: filteredModel
            spacing: 8
            highlightMoveDuration: 120

            delegate: Rectangle {
                width: appList.width
                height: 54
                radius: 14
                readonly property bool selected: ListView.isCurrentItem
                color: selected ? Qt.darker(launcher.pal.c13, 1.65) : (rowMouse.containsMouse ? launcher.pal.c0 : Qt.darker(launcher.pal.bg, 1.25))
                border.color: selected ? launcher.pal.c11 : (rowMouse.containsMouse ? launcher.pal.c13 : launcher.pal.c0)
                border.width: selected ? 2 : 1

                // Glowing Left Accent Bar on Selected App
                Rectangle {
                    visible: selected
                    width: 5; height: 32; radius: 2.5
                    x: 6; anchors.verticalCenter: parent.verticalCenter
                    color: launcher.pal.c11
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: selected ? 18 : 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // App Icon Box (Real System Icon + Fallback Glyph)
                    Rectangle {
                        width: 38; height: 38; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        color: selected ? launcher.pal.bg : launcher.pal.c0
                        border.color: selected ? launcher.pal.c13 : launcher.pal.c8
                        border.width: 1

                        Image {
                            id: appIconImg
                            anchors.fill: parent
                            anchors.margins: 5
                            source: model.icon || ""
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: appIconImg.status !== Image.Ready
                            text: "󰣆"
                            color: selected ? launcher.pal.c11 : launcher.pal.c6
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 20
                        }
                    }

                    // App Name + Description / Command Subtitle
                    Column {
                        width: parent.width - (selected ? 140 : 62)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: model.name
                            color: selected ? launcher.pal.fg : launcher.pal.c7
                            font.family: "Orbitron"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.desc || model.exec
                            color: selected ? launcher.pal.c12 : launcher.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    // Action Pill on Selected Row
                    Rectangle {
                        visible: selected
                        width: 74; height: 26; radius: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: launcher.pal.c11
                        Text {
                            anchors.centerIn: parent
                            text: "LAUNCH ⏎"
                            color: launcher.pal.bg
                            font.family: "Orbitron"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: appList.currentIndex = index
                    onClicked: {
                        appList.currentIndex = index
                        launcher.launchSelected()
                    }
                }
            }
        }

        // Custom Glowing Cyber Scrollbar Track
        Rectangle {
            id: scrollTrack
            width: 8
            anchors.top: appList.top
            anchors.bottom: appList.bottom
            anchors.right: parent.right
            anchors.rightMargin: 12
            radius: 4
            color: Qt.darker(launcher.pal.bg, 1.5)
            border.color: launcher.pal.c0
            border.width: 1

            Rectangle {
                width: parent.width
                radius: 4
                color: launcher.pal.c13
                height: Math.max(28, parent.height * appList.visibleArea.heightRatio)
                y: Math.max(0, Math.min(parent.height - height, parent.height * appList.visibleArea.yPosition))
                Behavior on y { NumberAnimation { duration: 60 } }
            }
        }
    }

    // 4. Little Webbed Feet Underneath
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 444
        spacing: 130
        Repeater {
            model: 2
            Rectangle {
                width: 54; height: 22; radius: 11
                color: launcher.pal.bg
                border.color: launcher.pal.c13
                border.width: 3
            }
        }
    }
}
