/*
This file is part of harbour-rutefisk.

    harbour-rutefisk is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    harbour-rutefisk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with harbour-rutefisk.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
  id: travelFromToOptionsPage
  property string fromID
  property string fromName
  property string toID
  property string toName
  property bool isafter: true
  property var date: new Date()
  property string datestring: date.toLocaleDateString(Qt.locale())
  property var time: new Date()
  property string timestring: time.toLocaleTimeString(Qt.locale())
  property real changemargin: 2
  property real changepunish: 8
  property real walkingfactor: 100
  property real maxwalkingminutes: 20
  property bool airportbus: true
  property bool airporttrain: true
  property bool bus: true
  property bool train: true
  property bool boat: true
  property bool metro: true
  property bool tram: true

  onDateChanged: {
    datestring = date.toLocaleDateString(Qt.locale())
  }
  onTimeChanged: {
    timestring = time.toLocaleTimeString(Qt.locale())
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: contentColumn.height


    Column {
      id: contentColumn
      width: parent.width

      PageHeader {
        id: pageHeader
        title: qsTr("Travel search options")
      }

      Button {
        text: qsTr("Search")
        onClicked: {
          pageStack.push(Qt.resolvedUrl("TravelFromTo.qml"), {
                           "fromID": fromID,
                           "fromName": fromName,
                           "toID": toID,
                           "toName": toName,
                           "isafter": isafter,
                           "date": date,
                           "time": time,
                           "changemargin": changemargin,
                           "changepunish": changepunish,
                           "walkingfactor": walkingfactor,
                           "maxwalkingminutes": maxwalkingminutes,
                           "airportbus": airportbus,
                           "airporttrain": airporttrain,
                           "bus": bus,
                           "train": train,
                           "boat": boat,
                           "metro": metro,
                           "tram": tram
                         });
        }
      }

      SectionHeader {
        text: qsTr("Travel time")
      }
      TextSwitch {
        description: qsTr("Travel is to start after selected time and date or before")
        text: qsTr("Before")
        checked: travelFromToOptionsPage.isafter
        onCheckedChanged: {
          travelFromToOptionsPage.isafter = checked
          if(checked) {
            text = qsTr("After")
          } else {
            text = qsTr("Before")
          }
        }
      }
      Column {
        Label {
          text: datestring
        }

        Button {
          text: qsTr("Change date")
          onClicked: {
            var dialog = pageStack.push(datePicker, {date: travelFromToOptionsPage.date});
            dialog.accepted.connect(function() {
              travelFromToOptionsPage.date = dialog.date
            } );
          }
        }
        Component {
          id: datePicker
          DatePickerDialog { }
        }
      }
      Column {
        Label {
          text: timestring
        }

        Button {
          text: qsTr("Change time")
          onClicked: {
            var dialog = pageStack.push(timePicker, {"hour": travelFromToOptionsPage.time.getHours(), "minute": travelFromToOptionsPage.time.getMinutes()});
            dialog.accepted.connect(function() {
              travelFromToOptionsPage.time = dialog.time
            } );
          }
        }
        Component {
          id: timePicker
          TimePickerDialog { }
        }
      }

      SectionHeader {
        text: qsTr("Transport types")
      }
      TextSwitch {
        text: qsTr("Bus")
        checked: travelFromToOptionsPage.bus
        onCheckedChanged: {
          travelFromToOptionsPage.bus = checked
        }
      }
      TextSwitch {
        text: qsTr("Metro")
        checked: travelFromToOptionsPage.metro
        onCheckedChanged: {
          travelFromToOptionsPage.metro = checked
        }
      }
      TextSwitch {
        text: qsTr("Tram")
        checked: travelFromToOptionsPage.tram
        onCheckedChanged: {
          travelFromToOptionsPage.tram = checked
        }
      }
      TextSwitch {
        text: qsTr("Train")
        checked: travelFromToOptionsPage.train
        onCheckedChanged: {
          travelFromToOptionsPage.train = checked
        }
      }
      TextSwitch {
        text: qsTr("Boat")
        checked: travelFromToOptionsPage.boat
        onCheckedChanged: {
          travelFromToOptionsPage.boat = checked
        }
      }
      TextSwitch {
        text: qsTr("Airport bus")
        checked: travelFromToOptionsPage.airportbus
        onCheckedChanged: {
          travelFromToOptionsPage.airportbus = checked
        }
      }
      TextSwitch {
        text: qsTr("Airport train")
        checked: travelFromToOptionsPage.airporttrain
        onCheckedChanged: {
          travelFromToOptionsPage.airporttrain = checked
        }
      }

      SectionHeader {
        text: qsTr("Change options")
      }
      Slider {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 0
        maximumValue: 99
        stepSize: 1.0
        label: qsTr("Minutes needed for interchange")
        valueText: value
        Component.onCompleted: {
          value = travelFromToOptionsPage.changemargin
        }
        onValueChanged: {
          travelFromToOptionsPage.changemargin = value
        }
      }
      Slider {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 0
        maximumValue: 199
        stepSize: 1.0
        label: qsTr("Minutes punishment for an interchange")
        valueText: value
        Component.onCompleted: {
          value = travelFromToOptionsPage.changepunish
        }
        onValueChanged: {
          travelFromToOptionsPage.changepunish = value
        }
      }

      SectionHeader {
        text: qsTr("Walking")
      }
      Slider {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 1
        maximumValue: 699
        stepSize: 1.0
        label: qsTr("Walking speed")
        valueText: value + qsTr("m/min")
        Component.onCompleted: {
          value = travelFromToOptionsPage.walkingfactor * 70 / 100
        }
        onValueChanged: {
          travelFromToOptionsPage.walkingfactor = value * 100 / 70 // walkingfactor is in percent of 70 m/min
        }
      }
      Slider {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 1
        maximumValue: 699
        stepSize: 1.0
        label: qsTr("Maximum minutes to walk to a stop")
        valueText: value
        Component.onCompleted: {
          value = travelFromToOptionsPage.maxwalkingminutes
        }
        onValueChanged: {
          travelFromToOptionsPage.maxwalkingminutes = value
        }
      }
    }
  }
}
