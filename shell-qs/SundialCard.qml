import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: sundial
    width: 430
    height: 550

    property var pal
    property var weather: ({ temp: "72°F", desc: "Clear Sky", icon: "󰖙" })
    property string clockStr: "00:00"
    property string dateStr: "SUN OCT 25"

    property real tickPhase: 0

    // Interactive Calendar & Google Calendar State
    property int viewYear: 2026
    property int viewMonth: 9        // 0-indexed (Oct = 9)
    property int selectedDay: 25
    property string selectedDateIso: "2026-10-25"
    property string monthTitle: "OCTOBER 2026"
    property var calDays: []
    property var allEvents: []
    property var selectedDayEvents: []
    property bool calLinked: false
    property bool showUrlDrawer: false

    Timer {
        interval: 45
        running: sundial.visible
        repeat: true
        onTriggered: sundial.tickPhase = (sundial.tickPhase + 1) % 1000
    }

    Process {
        id: calProc
        command: [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "calendar"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                try {
                    const lines = data.trim().split("\n")
                    const obj = JSON.parse(lines[lines.length - 1])
                    sundial.calLinked = obj.linked
                    sundial.allEvents = obj.events || []
                    sundial.rebuildGrid()
                    sundial.updateSelectedEvents()
                } catch (e) {}
            }
        }
    }

    function reloadCalendar(mode, urlArg) {
        if (mode === "set-url" && urlArg) {
            calProc.command = [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "calendar", "set-url", urlArg]
        } else if (mode === "refresh") {
            calProc.command = [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "calendar", "refresh"]
        } else {
            calProc.command = [Quickshell.env("HOME") + "/rice/shell-qs/sysinfo.sh", "calendar"]
        }
        calProc.running = false
        calProc.running = true
    }

    function hasEventsOn(y, m, d) {
        const iso = y + "-" + String(m + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0")
        for (let i = 0; i < allEvents.length; i++) {
            if (allEvents[i].date === iso) return true
        }
        return false
    }

    function updateSelectedEvents() {
        const mm = String(viewMonth + 1).padStart(2, "0")
        const dd = String(selectedDay).padStart(2, "0")
        selectedDateIso = viewYear + "-" + mm + "-" + dd
        let matches = []
        for (let i = 0; i < allEvents.length; i++) {
            if (allEvents[i].date === selectedDateIso) {
                matches.push(allEvents[i])
            }
        }
        selectedDayEvents = matches
    }

    function jumpToToday() {
        const now = new Date()
        viewYear = now.getFullYear()
        viewMonth = now.getMonth()
        selectedDay = now.getDate()
        rebuildGrid()
        updateSelectedEvents()
    }

    function shiftMonth(delta) {
        let m = viewMonth + delta
        let y = viewYear
        if (m < 0) { m = 11; y-- }
        else if (m > 11) { m = 0; y++ }
        viewMonth = m
        viewYear = y
        const maxD = new Date(viewYear, viewMonth + 1, 0).getDate()
        if (selectedDay > maxD) selectedDay = maxD
        rebuildGrid()
        updateSelectedEvents()
    }

    function rebuildGrid() {
        const now = new Date()
        const realY = now.getFullYear()
        const realM = now.getMonth()
        const realD = now.getDate()

        const mNames = ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
        monthTitle = mNames[viewMonth] + " " + viewYear

        const firstDay = new Date(viewYear, viewMonth, 1).getDay()
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()

        let arr = []
        for (let i = 0; i < firstDay; i++) {
            arr.push({ dayNum: 0, isToday: false, hasEv: false })
        }
        for (let d = 1; d <= daysInMonth; d++) {
            const isT = (viewYear === realY && viewMonth === realM && d === realD)
            arr.push({ dayNum: d, isToday: isT, hasEv: hasEventsOn(viewYear, viewMonth, d) })
        }
        calDays = arr
    }

    Component.onCompleted: {
        jumpToToday()
        reloadCalendar("", "")
    }

    onVisibleChanged: {
        if (visible) {
            showUrlDrawer = false
            reloadCalendar("", "")
        }
    }

    // 1. Sundial's 12 Rotating Celestial Sunburst Rays Around His Head!
    Item {
        width: 120; height: 120
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        rotation: sundial.tickPhase * 0.4

        Repeater {
            model: 12
            Rectangle {
                width: 16; height: 16; radius: 3
                color: index % 2 === 0 ? sundial.pal.c3 : sundial.pal.c11
                anchors.centerIn: parent
                rotation: index * 30
                transform: Translate {
                    x: Math.cos(index * 30 * Math.PI / 180) * 48
                    y: Math.sin(index * 30 * Math.PI / 180) * 48
                }
            }
        }
    }

    // 2. Sundial's Round Celestial Sun-Disc Face + Half-Rim Librarian Glasses!
    Rectangle {
        width: 96; height: 96; radius: 48
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        color: sundial.pal.bg
        border.color: sundial.pal.c3
        border.width: 3.5

        MouseArea { anchors.fill: parent }

        // Wise Raised Eyebrows
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 22
            spacing: 22
            Repeater {
                model: 2
                Rectangle {
                    width: 18; height: 3; radius: 1.5
                    color: sundial.pal.c3
                    rotation: index === 0 ? -8 : 8
                }
            }
        }

        // Half-Rim Reading Spectacles Perched on His Nose!
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 32
            spacing: 10
            Repeater {
                model: 2
                Rectangle {
                    width: 30; height: 22; radius: 9
                    color: Qt.darker(sundial.pal.bg, 1.35)
                    border.color: sundial.pal.c11
                    border.width: 2.5

                    // Warm Sun-Pupils Looking Down at Your Calendar
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 7
                        color: sundial.pal.c3
                    }
                }
            }
        }

        // Spectacles Bridge
        Rectangle {
            width: 12; height: 3
            anchors.horizontalCenter: parent.horizontalCenter
            y: 41
            color: sundial.pal.c11
        }

        // Gentle Wise Smile
        Rectangle {
            width: 20; height: 6; radius: 3
            anchors.horizontalCenter: parent.horizontalCenter
            y: 66
            color: sundial.pal.c11
        }
    }

    // 3. Sundial's Schedule & Weather Belly (Expanded Agenda View!)
    Rectangle {
        width: 404
        height: 398
        radius: 28
        anchors.horizontalCenter: parent.horizontalCenter
        y: 96
        color: sundial.pal.bg
        border.color: sundial.pal.c3
        border.width: 3
        z: 2

        MouseArea { anchors.fill: parent; z: -1 }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            // A. Top Local 92103 Weather & Today Banner
            Rectangle {
                width: parent.width
                height: 50
                radius: 14
                color: Qt.darker(sundial.pal.bg, 1.38)
                border.color: sundial.pal.c0; border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 14
                    spacing: 10

                    Column {
                        width: parent.width * 0.52
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: "SUNDIAL // PLANNER"
                            color: sundial.pal.c3
                            font.family: "Orbitron"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            text: sundial.dateStr + " • HILLCREST"
                            color: sundial.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }

                    Row {
                        width: parent.width * 0.48
                        anchors.verticalCenter: parent.verticalCenter
                        layoutDirection: Qt.RightToLeft
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: sundial.weather.icon || "󰖙"
                            color: sundial.pal.c3
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.right: parent.right
                                text: sundial.weather.temp || "72°F"
                                color: sundial.pal.fg
                                font.family: "Orbitron"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            Text {
                                anchors.right: parent.right
                                text: sundial.weather.desc || "Clear Sky"
                                color: sundial.pal.c12
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }

            // B. Month Navigation Header (< PREV | MONTH YEAR | TODAY | NEXT >)
            Row {
                width: parent.width
                height: 24
                spacing: 6

                Rectangle {
                    width: 28; height: 22; radius: 6
                    color: sundial.pal.c0
                    border.color: sundial.pal.c8; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "◀"
                        color: sundial.pal.c3
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: sundial.shiftMonth(-1)
                    }
                }

                Text {
                    width: parent.width - 134
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "󰃭 " + sundial.monthTitle
                    color: sundial.pal.c3
                    font.family: "Orbitron"
                    font.pixelSize: 11
                    font.bold: true
                }

                Rectangle {
                    width: 54; height: 22; radius: 6
                    color: sundial.pal.c0
                    border.color: sundial.pal.c4; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "TODAY"
                        color: sundial.pal.c4
                        font.family: "Orbitron"
                        font.pixelSize: 8
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: sundial.jumpToToday()
                    }
                }

                Rectangle {
                    width: 28; height: 22; radius: 6
                    color: sundial.pal.c0
                    border.color: sundial.pal.c8; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: sundial.pal.c3
                        font.pixelSize: 10
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: sundial.shiftMonth(1)
                    }
                }
            }

            // C. Interactive Monthly Calendar Grid
            Column {
                width: parent.width
                spacing: 2

                Row {
                    width: parent.width
                    Repeater {
                        model: ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]
                        Text {
                            width: parent.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: index === 0 || index === 6 ? sundial.pal.c6 : sundial.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }

                Grid {
                    id: calGrid
                    width: parent.width
                    columns: 7
                    rowSpacing: 2

                    Repeater {
                        model: sundial.calDays
                        Item {
                            id: dayCell
                            width: calGrid.width / 7
                            height: 22
                            readonly property int dNum: modelData.dayNum
                            readonly property bool today: modelData.isToday
                            readonly property bool hasEv: modelData.hasEv
                            readonly property bool isSel: dNum > 0 && dNum === sundial.selectedDay

                            Rectangle {
                                anchors.centerIn: parent
                                width: 32; height: 20; radius: 6
                                color: dayCell.isSel
                                    ? sundial.pal.c5
                                    : (dayCell.today ? sundial.pal.c3 : (dayMouse.containsMouse && dayCell.dNum > 0 ? sundial.pal.c0 : "transparent"))
                                border.color: dayCell.today ? sundial.pal.fg : (dayCell.isSel ? sundial.pal.c12 : "transparent")
                                border.width: (dayCell.today || dayCell.isSel) ? 1.5 : 0

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: dayCell.hasEv ? -2 : 0
                                    visible: dayCell.dNum > 0
                                    text: dayCell.dNum.toString()
                                    color: (dayCell.isSel || dayCell.today) ? sundial.pal.bg : sundial.pal.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: dayCell.isSel || dayCell.today || dayCell.hasEv
                                }

                                Rectangle {
                                    visible: dayCell.hasEv && dayCell.dNum > 0
                                    width: 5; height: 5; radius: 2.5
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 1.5
                                    color: (dayCell.isSel || dayCell.today) ? sundial.pal.bg : sundial.pal.c10
                                }
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: dayCell.dNum > 0
                                onClicked: {
                                    sundial.selectedDay = dayCell.dNum
                                    sundial.updateSelectedEvents()
                                }
                            }
                        }
                    }
                }
            }

            // D. Expanded Google Calendar Daily Agenda & Sync Drawer (Tall & Roomy!)
            Rectangle {
                width: parent.width
                height: 128
                radius: 14
                color: Qt.darker(sundial.pal.bg, 1.38)
                border.color: sundial.pal.c8; border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Row {
                        width: parent.width
                        height: 20
                        spacing: 6

                        Text {
                            width: parent.width - 134
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰃰  " + sundial.selectedDateIso + " (" + sundial.selectedDayEvents.length + ")"
                            color: sundial.pal.c12
                            font.family: "Orbitron"
                            font.pixelSize: 10
                            font.bold: true
                        }

                        Rectangle {
                            width: 48; height: 20; radius: 5
                            color: sundial.pal.c0
                            border.color: sundial.pal.c10; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "󰑓 SYNC"
                                color: sundial.pal.c10
                                font.family: "Orbitron"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: sundial.reloadCalendar("refresh", "")
                            }
                        }

                        Rectangle {
                            width: 72; height: 20; radius: 5
                            color: sundial.showUrlDrawer ? sundial.pal.c3 : sundial.pal.c0
                            border.color: sundial.pal.c3; border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: sundial.calLinked ? "󰌷 GCAL OK" : "󰌷 LINK GCAL"
                                color: sundial.showUrlDrawer ? sundial.pal.bg : sundial.pal.c3
                                font.family: "Orbitron"
                                font.pixelSize: 8
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    sundial.showUrlDrawer = !sundial.showUrlDrawer
                                    if (sundial.showUrlDrawer) gcalUrlInput.forceActiveFocus()
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: sundial.showUrlDrawer
                        width: parent.width
                        height: 80
                        radius: 8
                        color: Qt.darker(sundial.pal.bg, 1.55)
                        border.color: sundial.pal.c3; border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: "Paste Google Calendar 'Secret address in iCal format' URL:"
                                color: sundial.pal.c3
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }

                            Row {
                                width: parent.width
                                spacing: 6
                                Rectangle {
                                    width: parent.width - 62
                                    height: 26; radius: 5
                                    color: sundial.pal.bg
                                    border.color: sundial.pal.c8; border.width: 1
                                    TextInput {
                                        id: gcalUrlInput
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        color: sundial.pal.fg
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        clip: true
                                        Keys.onReturnPressed: saveUrlBtn.saveGcal()
                                    }
                                }
                                Rectangle {
                                    id: saveUrlBtn
                                    width: 54; height: 26; radius: 5
                                    color: sundial.pal.c10
                                    function saveGcal() {
                                        const u = gcalUrlInput.text.trim()
                                        if (u.length > 8) {
                                            sundial.showUrlDrawer = false
                                            sundial.reloadCalendar("set-url", u)
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "SAVE"
                                        color: sundial.pal.bg
                                        font.family: "Orbitron"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: saveUrlBtn.saveGcal()
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        visible: !sundial.showUrlDrawer
                        width: parent.width
                        height: 82
                        clip: true
                        spacing: 5
                        model: sundial.selectedDayEvents

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            radius: 6
                            color: Qt.darker(sundial.pal.bg, 1.2)
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8; anchors.rightMargin: 8
                                spacing: 8
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.time || "All Day"
                                    color: sundial.pal.c3
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                    width: 66
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.summary || "Event"
                                    color: sundial.pal.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width - 82
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: sundial.selectedDayEvents.length === 0
                            text: sundial.calLinked
                                ? "No events scheduled for this date."
                                : "Click [LINK GCAL] above to link your Google Calendar .ics URL!"
                            color: sundial.pal.c8
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    // 4. Owl Talons Underneath
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 498
        spacing: 120
        z: 3
        Repeater {
            model: 2
            Rectangle {
                width: 48; height: 18; radius: 9
                color: sundial.pal.bg
                border.color: sundial.pal.c3
                border.width: 3
            }
        }
    }
}
