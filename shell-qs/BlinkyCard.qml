import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Item {
    id: blinky
    width: 430
    height: 470

    property var pal
    property var sys: ({ ssid: "Online", bton: true })

    property string activeTab: "wifi" // "wifi" or "bt"
    property bool wifiOn: true
    property bool btOn: true
    property bool scanning: false
    property real lurePhase: 0

    // Inline Wi-Fi Password Drawer State
    property string pendingSsid: ""
    property string statusMsg: ""

    ListModel { id: wifiModel }
    ListModel { id: btModel }

    function refreshNet(doScan) {
        scanning = true
        statusMsg = doScan
            ? (activeTab === "bt" ? "Scanning nearby Bluetooth..." : "Rescanning Wi-Fi...")
            : ""
        netProc.command = doScan
            ? [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "net", "scan"]
            : [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "net"]
        netProc.running = false
        netProc.running = true
    }

    onVisibleChanged: {
        if (visible) {
            pendingSsid = ""
            statusMsg = ""
            refreshNet(false)
        }
    }

    Process {
        id: netProc
        command: [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "net"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                blinky.scanning = false
                blinky.statusMsg = ""
                try {
                    const lines = data.trim().split("\n")
                    const obj = JSON.parse(lines[lines.length - 1])
                    blinky.wifiOn = obj.wifi_on
                    blinky.btOn = obj.bt_on
                    wifiModel.clear()
                    for (let i = 0; i < obj.wifi.length; i++) wifiModel.append(obj.wifi[i])
                    btModel.clear()
                    for (let j = 0; j < obj.bt.length; j++) btModel.append(obj.bt[j])
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 75
        running: blinky.visible
        repeat: true
        onTriggered: blinky.lurePhase = (blinky.lurePhase + 1) % 200
    }

    Timer {
        id: actionRefreshTimer
        interval: 1400
        onTriggered: blinky.refreshNet(false)
    }

    // Computed High-Contrast Lure Color:
    // Scanning -> Flashing Electric Blue (#00d8ff)
    // Connected -> Vivid Emerald Green (#00ff66)
    // Disconnected -> Error Crimson Red (#ff2244)
    readonly property bool isConnected: blinky.wifiOn && blinky.sys.ssid !== "Wired/Offline" && blinky.sys.ssid !== ""
    readonly property color bulbColor: blinky.scanning
        ? ((Math.floor(blinky.lurePhase / 2) % 2 === 0) ? "#00d8ff" : "#0055ff")
        : (blinky.isConnected ? "#00ff66" : "#ff2244")

    // 1. Curved Angler Stalk & High-Visibility Bioluminescent Lure Bulb
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: blinky.bulbColor
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 215; startY: 56
            PathCubic {
                x: 125 + Math.sin(blinky.lurePhase * 0.12) * 8
                y: 22 + Math.cos(blinky.lurePhase * 0.12) * 5
                control1X: 215; control1Y: 6
                control2X: 145; control2Y: 2
            }
        }
    }

    // Triple-Halo Angler Lure Bulb
    Rectangle {
        width: 34; height: 34; radius: 17
        x: 108 + Math.sin(blinky.lurePhase * 0.12) * 8
        y: 6 + Math.cos(blinky.lurePhase * 0.12) * 5
        color: blinky.bulbColor
        border.color: "#ffffff"
        border.width: 2.5

        // Outer Glow Ring 1
        Rectangle {
            anchors.centerIn: parent
            width: 52; height: 52; radius: 26
            color: blinky.bulbColor
            opacity: blinky.scanning ? 0.55 : 0.32
        }
        // Outer Glow Ring 2
        Rectangle {
            anchors.centerIn: parent
            width: 68; height: 68; radius: 34
            color: blinky.bulbColor
            opacity: 0.14
        }

        // Status Glyph Inside the Bulb (✓, !, or BT Scan Wave)
        Text {
            anchors.centerIn: parent
            text: blinky.scanning ? "󰂰" : (blinky.isConnected ? "󰖩" : "!")
            color: "#0b0d12"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            font.bold: true
        }
    }

    // 2. Spiky Abyssal Side Fins
    Rectangle {
        width: 38; height: 20; radius: 6
        color: blinky.pal.c4
        x: 92; y: 74
        transformOrigin: Item.Right
        rotation: -18 + Math.sin(blinky.lurePhase * 0.25) * 14
    }
    Rectangle {
        width: 38; height: 20; radius: 6
        color: blinky.pal.c4
        x: 300; y: 74
        transformOrigin: Item.Left
        rotation: 18 - Math.sin(blinky.lurePhase * 0.25) * 14
    }

    // 3. Blinky's Wide Lantern-Jawed Angler Head (With Little Underbite Fangs!)
    Rectangle {
        width: 188; height: 68; radius: 32
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48
        color: blinky.pal.bg
        border.color: blinky.bulbColor
        border.width: 3

        MouseArea { anchors.fill: parent }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12
            spacing: 38
            Repeater {
                model: 2
                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Qt.darker(blinky.pal.bg, 1.4)
                    border.color: blinky.bulbColor
                    border.width: 2
                    Rectangle {
                        width: 14; height: 14; radius: 7
                        color: blinky.bulbColor
                        x: 6 + Math.sin(blinky.lurePhase * 0.1) * 4
                        y: 6
                    }
                }
            }
        }

        // Cute Little Angler Underbite Fangs Along Bottom Jaw
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 52
            spacing: 18
            Repeater {
                model: 4
                Rectangle {
                    width: 8; height: 8; radius: 1
                    rotation: 45
                    color: blinky.pal.fg
                }
            }
        }
    }

    // 4. Blinky's Self-Contained Sonar Belly (Wi-Fi & Bluetooth Applet)
    Rectangle {
        width: 400
        height: 314
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 120
        color: blinky.pal.bg
        border.color: blinky.bulbColor
        border.width: 3
        MouseArea { anchors.fill: parent; z: -1 }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // Top Mode Tabs (Wi-Fi vs Bluetooth)
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) * 0.5
                    height: 34; radius: 11
                    color: blinky.activeTab === "wifi" ? blinky.pal.c4 : blinky.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: "󰖩  Wi-Fi (" + (blinky.wifiOn ? "ON" : "OFF") + ")"
                        color: blinky.activeTab === "wifi" ? blinky.pal.bg : blinky.pal.fg
                        font.family: "Orbitron"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            blinky.activeTab = "wifi"
                            blinky.pendingSsid = ""
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) * 0.5
                    height: 34; radius: 11
                    color: blinky.activeTab === "bt" ? blinky.pal.c5 : blinky.pal.c0
                    Text {
                        anchors.centerIn: parent
                        text: "󰂯  Bluetooth (" + (blinky.btOn ? "ON" : "OFF") + ")"
                        color: blinky.activeTab === "bt" ? blinky.pal.bg : blinky.pal.fg
                        font.family: "Orbitron"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            blinky.activeTab = "bt"
                            blinky.pendingSsid = ""
                        }
                    }
                }
            }

            // Built-In Radio Power + Active Discovery Sweep Controls (Zero External Terminal Needed!)
            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    width: (parent.width - 8) * 0.48
                    height: 30; radius: 9
                    color: Qt.darker(blinky.pal.bg, 1.35)
                    border.color: blinky.pal.c8; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: blinky.activeTab === "wifi"
                            ? (blinky.wifiOn ? "󰖪  Turn Wi-Fi OFF" : "󰖩  Turn Wi-Fi ON")
                            : (blinky.btOn ? "󰂲  Turn BT OFF" : "󰂯  Turn BT ON")
                        color: blinky.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (blinky.activeTab === "wifi") {
                                Quickshell.execDetached(["nmcli", "radio", "wifi", blinky.wifiOn ? "off" : "on"])
                            } else {
                                Quickshell.execDetached(["bluetoothctl", "power", blinky.btOn ? "off" : "on"])
                            }
                            actionRefreshTimer.restart()
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 8) * 0.52
                    height: 30; radius: 9
                    color: blinky.scanning ? blinky.pal.c11 : Qt.darker(blinky.pal.bg, 1.35)
                    border.color: blinky.scanning ? blinky.pal.fg : blinky.pal.c10
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: blinky.scanning
                            ? "󰑐  Scanning Airwaves..."
                            : (blinky.activeTab === "wifi" ? "󰑓  Scan Nearby Wi-Fi" : "󰂰  Scan Nearby BT Devices")
                        color: blinky.scanning ? blinky.pal.bg : blinky.pal.c10
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: !blinky.scanning
                        onClicked: blinky.refreshNet(true)
                    }
                }
            }

            // Inline Wi-Fi Password Input Bar (Appears Automatically When Connecting to a Locked SSID)
            Rectangle {
                visible: blinky.pendingSsid !== "" && blinky.activeTab === "wifi"
                width: parent.width
                height: 38
                radius: 10
                color: Qt.darker(blinky.pal.bg, 1.5)
                border.color: blinky.pal.c11
                border.width: 2

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10; anchors.rightMargin: 8
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰌾"
                        color: blinky.pal.c11
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: wifiPassInput
                        width: parent.width - 115
                        anchors.verticalCenter: parent.verticalCenter
                        color: blinky.pal.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        echoMode: TextInput.Password
                        clip: true
                        Keys.onReturnPressed: joinBtn.connectWithPass()
                        Keys.onEscapePressed: blinky.pendingSsid = ""
                    }

                    Rectangle {
                        id: joinBtn
                        width: 52; height: 24; radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: blinky.pal.c10
                        function connectWithPass() {
                            const s = blinky.pendingSsid
                            const p = wifiPassInput.text
                            blinky.pendingSsid = ""
                            wifiPassInput.text = ""
                            blinky.statusMsg = "Connecting to " + s + "..."
                            Quickshell.execDetached([Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "wifi-connect", s, p])
                            actionRefreshTimer.restart()
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "JOIN"
                            color: blinky.pal.bg
                            font.family: "Orbitron"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: joinBtn.connectWithPass()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "✕"
                        color: blinky.pal.c1
                        font.pixelSize: 14
                        MouseArea {
                            anchors.fill: parent
                            onClicked: blinky.pendingSsid = ""
                        }
                    }
                }
            }

            // Wi-Fi Networks List
            ListView {
                id: wifiList
                visible: blinky.activeTab === "wifi"
                width: parent.width
                height: blinky.pendingSsid !== "" ? 156 : 202
                clip: true
                spacing: 6
                model: wifiModel

                delegate: Rectangle {
                    width: wifiList.width
                    height: 42
                    radius: 10
                    color: model.active ? Qt.darker(blinky.pal.c4, 1.65) : (netMouse.containsMouse ? blinky.pal.c0 : Qt.darker(blinky.pal.bg, 1.25))
                    border.color: model.active ? blinky.pal.c10 : blinky.pal.c0
                    border.width: model.active ? 2 : 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.active ? "󰖩" : (model.sec !== "Open" ? "󰌾" : "󰖩")
                            color: model.active ? blinky.pal.c10 : blinky.pal.c4
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                        }

                        Column {
                            width: parent.width - 150
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                width: parent.width
                                text: model.ssid
                                color: blinky.pal.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: model.active
                                elide: Text.ElideRight
                            }
                            Text {
                                text: model.sec + "  •  " + model.signal + "% signal"
                                color: blinky.pal.c8
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }

                        // Connect / Disconnect Pill
                        Rectangle {
                            width: 64; height: 24; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: model.active ? blinky.pal.c10 : blinky.pal.c4
                            Text {
                                anchors.centerIn: parent
                                text: model.active ? "ACTIVE" : "JOIN"
                                color: blinky.pal.bg
                                font.family: "Orbitron"
                                font.pixelSize: 9
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (model.active) {
                                        Quickshell.execDetached(["nmcli", "connection", "down", model.ssid])
                                        actionRefreshTimer.restart()
                                    } else {
                                        Quickshell.execDetached([Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "wifi-connect", model.ssid])
                                        actionRefreshTimer.restart()
                                    }
                                }
                            }
                        }

                        // Password Key Button (For new secured Wi-Fi networks)
                        Rectangle {
                            visible: !model.active && model.sec !== "Open"
                            width: 26; height: 24; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: blinky.pal.c0
                            border.color: blinky.pal.c11; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "󰌆"
                                color: blinky.pal.c11
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    blinky.pendingSsid = model.ssid
                                    wifiPassInput.text = ""
                                    wifiPassInput.forceActiveFocus()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                    }
                }
            }

            // Built-In Bluetooth Devices Applet List (Pair, Connect, Disconnect, Forget)
            ListView {
                id: btList
                visible: blinky.activeTab === "bt"
                width: parent.width
                height: 202
                clip: true
                spacing: 6
                model: btModel

                delegate: Rectangle {
                    width: btList.width
                    height: 44
                    radius: 10
                    color: model.connected ? Qt.darker(blinky.pal.c5, 1.65) : (btMouse.containsMouse ? blinky.pal.c0 : Qt.darker(blinky.pal.bg, 1.25))
                    border.color: model.connected ? blinky.pal.c10 : (model.paired ? blinky.pal.c5 : blinky.pal.c0)
                    border.width: model.connected ? 2 : 1

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.glyph || (model.connected ? "󰂱" : "󰂯")
                            color: model.connected ? blinky.pal.c10 : blinky.pal.c5
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                        }

                        Column {
                            width: parent.width - 148
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                width: parent.width
                                text: model.name
                                color: blinky.pal.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: model.connected
                                elide: Text.ElideRight
                            }
                            Text {
                                text: (model.connected ? "Connected • " : (model.paired ? "Paired • " : "Nearby • ")) + model.mac
                                color: model.connected ? blinky.pal.c10 : blinky.pal.c8
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }

                        // Connect / Pair / Disconnect Button
                        Rectangle {
                            width: 68; height: 26; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: model.connected ? blinky.pal.c10 : (model.paired ? blinky.pal.c5 : blinky.pal.c11)
                            Text {
                                anchors.centerIn: parent
                                text: model.connected ? "UNLINK" : (model.paired ? "CONNECT" : "PAIR+LINK")
                                color: blinky.pal.bg
                                font.family: "Orbitron"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    const act = model.connected ? "disconnect" : "connect"
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "bt-action", act, model.mac])
                                    actionRefreshTimer.restart()
                                }
                            }
                        }

                        // Forget / Remove Paired Device Button
                        Rectangle {
                            visible: model.paired
                            width: 24; height: 26; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: blinky.pal.c0
                            border.color: blinky.pal.c1; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: blinky.pal.c1
                                font.pixelSize: 11
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Quickshell.execDetached([Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "bt-action", "forget", model.mac])
                                    actionRefreshTimer.restart()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: btMouse
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                    }
                }
            }
        }
    }

    // 5. Little Flipper Feet Underneath
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 438
        spacing: 100
        Repeater {
            model: 2
            Rectangle {
                width: 52; height: 20; radius: 10
                color: blinky.pal.bg
                border.color: blinky.pal.c4
                border.width: 3
            }
        }
    }
}
