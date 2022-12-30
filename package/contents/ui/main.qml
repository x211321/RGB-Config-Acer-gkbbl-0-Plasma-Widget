// main.qml
import QtQuick 2.4
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Universal 2.12

import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import QtGraphicalEffects 1.0


Item {
    id: root

    property string icon: Qt.resolvedUrl("rgbconfig.svg")

    property var labelWidth: 80
    property var labelHeight: 30
    property var labelMargin: 5
    property var labelSpacing: 20

    readonly property int rgb_mode_static  : 0
    readonly property int rgb_mode_breath  : 1
    readonly property int rgb_mode_neon    : 2
    readonly property int rgb_mode_wave    : 3
    readonly property int rgb_mode_shifting: 4
    readonly property int rgb_mode_zoom    : 5

    readonly property var widgetStates: [
        {'mode': rgb_mode_static  , 'speed': 0, 'direction': 0, 'colors': [1,1,1,1]},
        {'mode': rgb_mode_breath  , 'speed': 1, 'direction': 0, 'colors': [1,0,0,0]},
        {'mode': rgb_mode_neon    , 'speed': 1, 'direction': 0, 'colors': [0,0,0,0]},
        {'mode': rgb_mode_wave    , 'speed': 1, 'direction': 1, 'colors': [0,0,0,0]},
        {'mode': rgb_mode_shifting, 'speed': 1, 'direction': 1, 'colors': [1,0,0,0]},
        {'mode': rgb_mode_zoom    , 'speed': 1, 'direction': 0, 'colors': [1,0,0,0]}
    ]



    //###################
    // COMPACT
    //-------------------
    Plasmoid.compactRepresentation: Item {
        PlasmaCore.IconItem {
            id: compact
            anchors.fill: parent
            source: icon
            antialiasing: true
        }
        ColorOverlay {
            anchors.fill: compact
            source: compact
            color: plasmoid.configuration.customIconColor
            antialiasing: true
        }
    }


    //###################
    // FULL
    //-------------------
    Plasmoid.fullRepresentation: ColumnLayout {

        spacing: 5

        Component.onCompleted: {
            updateRGBMode()    
        }

        function updateRGBMode(apply = false) {
            var mode = comboboxRGBMode.currentValue

            speedSlider.enabled             = widgetStates[mode].speed;
            directionRadioLeftRight.enabled = widgetStates[mode].direction;
            directionRadioRightLeft.enabled = widgetStates[mode].direction;

            var hasColors = false

            for (var i = 0; i < colorRepeater.count; i++) {
                // Disable color rect depending on available color sections
                colorRepeater.itemAt(i).enabled = widgetStates[mode].colors[i]

                // Hide color rect depending on available color section
                if (widgetStates[mode].colors[i]) {
                    colorRepeater.itemAt(i).visible = true
                    hasColors = true
                }else{
                    colorRepeater.itemAt(i).visible = false
                }
                
                // Set text colors according to the selected background color
                var r = parseInt(colorRepeater.itemAt(i).color.toString().substring(1, 3), 16)
                var g = parseInt(colorRepeater.itemAt(i).color.toString().substring(3, 5), 16)
                var b = parseInt(colorRepeater.itemAt(i).color.toString().substring(5, 7), 16)

                if ((r*0.299 + g*0.587 + b*0.114) > 186) {
                    colorRepeater.itemAt(i).textColor = "black"
                } else {
                    colorRepeater.itemAt(i).textColor = "white"
                }

                // Hide colors label when no colors are selectable
                // (only hide text - keep actual label so that the window size doesn't change)
                if (!hasColors) {
                    colorLabel.text = ""
                } else {
                    colorLabel.text = i18n("Colors")
                }
            }

            if (apply) {
                applyRGBSettings()
            }
        }

        function applyRGBSettings() {

            // Save configuration
            plasmoid.configuration.mode       = comboboxRGBMode.currentValue
            plasmoid.configuration.brightness = brightnessSlider.value
            plasmoid.configuration.speed      = speedSlider.value
            plasmoid.configuration.leftRight  = directionRadioLeftRight.checked
            plasmoid.configuration.rightLeft  = directionRadioRightLeft.checked
            
            var colors = []

            for (var i = 0; i < colorRepeater.count; i++) {
                colors.push(colorRepeater.itemAt(i).color.toString())
            }

            plasmoid.configuration.colors = colors

            // Apply RGB settings
            // - run included python script via PlasmaCode.DataSource
            var scriptPath = plasmoid.metaData.fileName.split("/").slice(0, -1).join("/")+"/contents/scripts/"
            command.exec(
                "python3 " + scriptPath + "applyRGBSettings.py" +
                " -m " + comboboxRGBMode.currentValue + 
                " -b " + brightnessSlider.value + 
                " -s " + speedSlider.value + 
                " -d " + (directionRadioLeftRight.checked ? 1 : 0) + 
                " -c " + colors.map(function(color){return color.replace("#", "")})
            );
        }


        PlasmaCore.DataSource {
            id: command
            engine: "executable"
            connectedSources: []
            onNewData: {
                var stdout = data["stdout"]
                var stderr = data["stderr"]
                commandExecuted(sourceName, stdout, stderr)
                disconnectSource(sourceName)
            }
            
            function exec(cmd) {
                connectSource(cmd)
            }

            signal commandExecuted(string sourceName, string stdout, string stderr)
        }

        PlasmaCore.DataSource {
            id: notification
            engine: "notifications"
            connectedSources: "org.freedesktop.Notifications"
        }

        function missingCharacterDeviceNotification(message) {
            var service = notification.serviceForSource("notification");
            var operation = service.operationDescription("missingCharacterDeviceNotification");

            operation.appName = i18n("RGB config (Acer)")
            operation["appIcon"] = "data-error"
            operation.summary = i18n("Character device not available")
            operation["body"] = message
            operation["timeout"] = 2000

            service.startOperationCall(operation);
        }

        function unexpectedErrorNotification(message) {
            var service = notification.serviceForSource("notification");
            var operation = service.operationDescription("unexpectedErrorNotification");

            operation.appName = i18n("RGB config (Acer)")
            operation["appIcon"] = "data-error"
            operation.summary = i18n("Unexpected error"")
            operation["body"] = message
            operation["timeout"] = 2000

            service.startOperationCall(operation);
        }

        Connections {
            target: command
            function onCommandExecuted(command, stdout, stderr) {
                // console.log("CMD: ", command)
                // console.log("OUT: ", stdout)
                // console.log("ERR: ", stderr)

                if (parseInt(stdout)) {
                    switch(parseInt(stdout)) {
                        case 1:
                            missingCharacterDeviceNotification(i18n("The character device at /dev/acer-gkbbl-0 is not available. Please make sure the necessary kernel module is installed and loaded."))
                            break;
                        case 2:
                            missingCharacterDeviceNotification(i18n("The character device at /dev/acer-gkbbl-static-0 is not available. Please make sure the necessary kernel module is installed and loaded."))
                            break;
                    } 
                } else {
                    if (stderr.length) {
                        unexpectedErrorNotification(stderr)
                    }
                }
            }
        }



        //###################
        // Header
        //-------------------
        Row {
            spacing: labelSpacing
            visible: plasmoid.configuration.showHeader

            PlasmaComponents.Label {width: labelMargin}

            PlasmaComponents.Label {
                text: i18n("RGB Config (Acer)")
                font.bold: true
                font.pointSize: 13
                width: labelWidth
                height: labelHeight
            }

            PlasmaComponents.Label {width: labelMargin}
        }

        //###################
        // RGB Mode
        //-------------------
        Row {
            spacing: labelSpacing

            PlasmaComponents.Label {width: labelMargin}

            PlasmaComponents.Label {
                text: i18n("RGB Mode")
                width: labelWidth
                height: labelHeight
            }
            
            PlasmaComponents.ComboBox {
                id: comboboxRGBMode
                textRole: "text"
                valueRole: "value"
                currentIndex: plasmoid.configuration.mode
                width: 200
                model: [
                    { value: rgb_mode_static  , text: i18n("Static") },
                    { value: rgb_mode_breath  , text: i18n("Breath") },
                    { value: rgb_mode_neon    , text: i18n("Neon") },
                    { value: rgb_mode_wave    , text: i18n("Wave") },
                    { value: rgb_mode_shifting, text: i18n("Shifting") },
                    { value: rgb_mode_zoom    , text: i18n("Zoom") },
                ]
                onActivated: updateRGBMode(true)
            }

            PlasmaComponents.Label {width: labelMargin}
        }


        //###################
        // Brightness
        //-------------------
        Row {
            spacing: labelSpacing

            PlasmaComponents.Label {width: labelMargin}

            PlasmaComponents.Label {
                text: i18n("Brightness")
                width: labelWidth
                height: labelHeight
            }

            PlasmaComponents.Slider {
                id: brightnessSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: plasmoid.configuration.brightness
                stepSize: 5
                onMoved: applyRGBSettings()
            }

            PlasmaComponents.Label {
                id: brightnessSliderLabel

                function formatText(value) {
                    return i18n("%1%", value)
                }

                text: formatText(brightnessSlider.value)

                TextMetrics {
                    id: brightnessTextMetrics
                    font.family: brightnessSliderLabel.font.family
                    font.pointSize: brightnessSliderLabel.font.pointSize
                    text: brightnessSliderLabel.formatText(brightnessSlider.to)
                }
                Layout.minimumWidth: brightnessTextMetrics.width
            }

            PlasmaComponents.Label {width: labelMargin}
        }


        //###################
        // Speed
        //-------------------
        Row {
            spacing: labelSpacing

            PlasmaComponents.Label {width: labelMargin}

            PlasmaComponents.Label {
                text: i18n("Speed")
                width: labelWidth
                height: labelHeight
            }

            PlasmaComponents.Slider {
                id: speedSlider
                Layout.fillWidth: true
                from: 0
                to: 9
                value: plasmoid.configuration.speed
                stepSize: 1
                onMoved: applyRGBSettings()
            }

            PlasmaComponents.Label {
                id: speedSliderLabel

                function formatText(value) {
                    return i18n("%1", value)
                }

                text: formatText(speedSlider.value)

                TextMetrics {
                    id: speedTextMetrics
                    font.family: speedSliderLabel.font.family
                    font.pointSize: speedSliderLabel.font.pointSize
                    text: speedSliderLabel.formatText(speedSlider.to)
                }
                Layout.minimumWidth: speedTextMetrics.width
            }

            PlasmaComponents.Label {width: labelMargin}
        }


        //###################
        // Direction
        //-------------------
        Row {
            spacing: labelSpacing

            PlasmaComponents.Label {width: labelMargin}
            
            PlasmaComponents.Label {
                text: i18n("Direction")
                width: labelWidth
                height: labelHeight
            }

            PlasmaComponents.RadioButton {
                id: directionRadioLeftRight
                text: i18n("Left to right")
                checked: plasmoid.configuration.leftRight
                autoExclusive: true
                onClicked: applyRGBSettings()
            }

            PlasmaComponents.RadioButton {
                id: directionRadioRightLeft
                text: i18n("Right to left")
                checked: plasmoid.configuration.rightLeft
                autoExclusive: true
                onClicked: applyRGBSettings()
            }

            PlasmaComponents.Label {width: labelMargin}
        }


        //###################
        // Colors
        //-------------------
        Row {
            spacing: labelSpacing

            PlasmaComponents.Label {width: labelMargin}

            PlasmaComponents.Label {
                id: colorLabel
                text: i18n("Colors")
                width: labelWidth
                height: labelHeight
            }

            Repeater {
                id: colorRepeater
                model: 4

                Rectangle {
                    property string textColor: "white"

                    id: colorRect
                    color: plasmoid.configuration.colors[index]
                    height: labelHeight
                    width: labelHeight
                    radius: width*0.1
                    border.color: "white"
                    border.width: 1
                    Text {
                        id: colorText
                        color: textColor
                        text: index+1
                        font.bold: true
                        font.pointSize: 13
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ColorDialog {
                        id: colorPicker
                        title: i18n("Color section " + (index+1))
                        color: colorRect.color
                        onAccepted: {
                            colorRect.color = color
                            updateRGBMode(true)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            colorPicker.open()
                        }

                        onEntered: {
                            colorRect.border.color = Universal.accent
                        }

                        onExited: {
                            colorRect.border.color = "white"
                        }
                    }
                }
            }

            PlasmaComponents.Label {width: labelMargin}
            
        }

        //###################
        // Spacer
        //-------------------
        Row {
            PlasmaComponents.Label {
                text: ""
                width: labelWidth
                height: labelHeight/2
            }
        }
    }
}
