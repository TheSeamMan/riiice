import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    readonly property string home: Quickshell.env("HOME")

    function playSound(name) {
        Quickshell.execDetached(["paplay", home + "/rice/picker-qs/" + name + ".wav"])
    }

    property double lastShift: 0
    property bool shuffling: false
    function noteShift() {
        lastShift = Date.now()
        if (!shuffling) startShuffle()
    }
    function startShuffle() {
        shuffling = true
        playSound("shuffle")
        shuffleTimer.restart()
    }
    Timer {
        id: shuffleTimer
        interval: 2600
        onTriggered: {
            if (Date.now() - root.lastShift < 800) root.startShuffle()
            else root.shuffling = false
        }
    }

    function pick(i) {
        if (i < 0 || i >= walls.count) return
        const file = walls.get(i).file
        const orig = home + "/rice/wallpapers/" + file.slice(0, file.length - 4)
        playSound("twinkle")
        Quickshell.execDetached([home + "/rice/scripts/setwall", orig])
        Qt.quit()
    }

    ListModel { id: walls }

    Process {
        command: ["sh", "-c", "ls -1 \"$HOME/rice/thumbs\""]
        running: true
        stdout: SplitParser {
            onRead: line => { if (line.length > 0) walls.append({ file: line }) }
        }
    }

    component Chevron: Shape {
        id: sh
        property color fill: "transparent"
        property color stroke: "transparent"
        property real strokeW: 0
        property real tip: 0.11
        ShapePath {
            fillColor: sh.fill
            strokeColor: sh.stroke
            strokeWidth: sh.strokeW
            joinStyle: ShapePath.MiterJoin
            startX: 0; startY: 0
            PathLine { x: sh.width * (1 - sh.tip); y: 0 }
            PathLine { x: sh.width; y: sh.height / 2 }
            PathLine { x: sh.width * (1 - sh.tip); y: sh.height }
            PathLine { x: sh.width * 0; y: sh.height }
            PathLine { x: sh.width * sh.tip; y: sh.height / 2 }
            PathLine { x: 0; y: 0 }
        }
    }

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "wallpaper-picker"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.024, 0.027, 0.035, 0.9)
            MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) Qt.quit()
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_A || event.key === Qt.Key_H) view.decrementCurrentIndex()
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_D || event.key === Qt.Key_L) view.incrementCurrentIndex()
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.pick(view.currentIndex)
            }
        }

        PathView {
            id: view
            anchors.fill: parent
            model: walls
            pathItemCount: 7
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 450
            snapMode: PathView.SnapOneItem

            readonly property real cardW: Math.min(width * 0.52, 1100)
            readonly property real cardH: cardW * 0.625
            property bool armed: false
            onCurrentIndexChanged: if (armed) root.noteShift()
            Timer { interval: 600; running: true; onTriggered: view.armed = true }

            path: Path {
                startX: -view.cardW * 0.2
                startY: view.height / 2
                PathAttribute { name: "z"; value: 0 }
                PathAttribute { name: "sc"; value: 0.5 }
                PathAttribute { name: "rot"; value: 48 }
                PathLine { x: view.width / 2; y: view.height / 2 }
                PathAttribute { name: "z"; value: 10 }
                PathAttribute { name: "sc"; value: 1.0 }
                PathAttribute { name: "rot"; value: 0 }
                PathLine { x: view.width + view.cardW * 0.2; y: view.height / 2 }
                PathAttribute { name: "z"; value: 0 }
                PathAttribute { name: "sc"; value: 0.5 }
                PathAttribute { name: "rot"; value: -48 }
            }

            delegate: Item {
                id: card
                width: view.cardW
                height: view.cardH
                z: PathView.z
                scale: PathView.sc
                opacity: Math.min(1, Math.max(0, (PathView.sc - 0.5) * 4))
                property real rot: PathView.rot
                property bool current: PathView.isCurrentItem
                property real norm: (x + width / 2 - view.width / 2) / (view.width / 2)
                property color edge: current ? "#00f0ff" : "#f5bd1f"
                Behavior on edge { ColorAnimation { duration: 220 } }

                readonly property string thumbUrl: "file://" + root.home + "/rice/thumbs/" + encodeURIComponent(model.file)
                readonly property string origUrl: "file://" + root.home + "/rice/wallpapers/" + encodeURIComponent(model.file.slice(0, model.file.length - 4))

                transform: Rotation {
                    origin.x: card.width / 2
                    origin.y: card.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: card.rot
                }

                Item {
                    id: crop
                    width: card.width
                    height: card.height
                    clip: true
                    visible: false

                    Image {
                        anchors.fill: parent
                        source: card.thumbUrl
                        sourceSize.width: 6
                        sourceSize.height: 4
                        fillMode: Image.Stretch
                        smooth: true
                        asynchronous: true
                    }
                    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.35 }

                    Image {
                        width: card.width * 0.94
                        height: card.height * 0.94
                        y: (card.height - height) / 2
                        x: (card.width - width) / 2 - card.norm * card.width * 0.03
                        source: card.origUrl
                        sourceSize.width: 2400
                        sourceSize.height: 1500
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }
                }

                Chevron {
                    id: maskShape
                    width: card.width
                    height: card.height
                    fill: "white"
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: parent
                    source: crop
                    maskEnabled: true
                    maskSource: maskShape
                    brightness: card.current ? 0.0 : -0.3
                    Behavior on brightness { NumberAnimation { duration: 220 } }
                }

                Chevron { anchors.fill: parent; stroke: card.edge; strokeW: card.current ? 26 : 14; opacity: card.current ? 0.30 : 0.16 }
                Chevron { anchors.fill: parent; stroke: card.edge; strokeW: card.current ? 10 : 7 }
                Chevron { anchors.fill: parent; stroke: card.current ? "#ffffff" : "#ffe89e"; strokeW: 2.5; opacity: 0.8 }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (card.current) root.pick(index)
                        else view.currentIndex = index
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            z: 100
            acceptedButtons: Qt.NoButton
            property real acc: 0
            onWheel: wheel => {
                acc += (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x)
                while (acc >= 120) { view.decrementCurrentIndex(); acc -= 120 }
                while (acc <= -120) { view.incrementCurrentIndex(); acc += 120 }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            color: "#9a9a9a"
            font.pixelSize: 15
            text: (view.currentIndex + 1) + " / " + walls.count + "      <-  -> browse      enter apply      esc close"
        }
    }
}
