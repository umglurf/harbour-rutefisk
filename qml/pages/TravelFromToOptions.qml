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
  property var lines: new Array()
  property var available_lines: new Object()

  onDateChanged: {
    datestring = date.toLocaleDateString(Qt.locale())
  }
  onTimeChanged: {
    timestring = time.toLocaleTimeString(Qt.locale())
  }

  Component.onCompleted: {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      if(xhr.readyState == 4 && xhr.status == 200) {
        var data = JSON.parse(xhr.responseText);
        for(var index=0; index < data.length; index++) {
          if(lines.indexOf(data[index]['Name']) == -1) {
            available_lines[data[index]['Name']] = 1;
          } else {
            available_lines[data[index]['Name']] = 0;
          }
        };
      };
    };
    xhr.open("GET", "http://reisapi.ruter.no/Line/GetLines", true);
    xhr.send();
  }

  ListModel {
    id: linesModel

    Component.onCompleted: {
        for(var i=0; i < lines.length; i++) {
            append({"line": lines[i]});
        }
    }
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
          var l = [];
          for(var i = 0; i < linesModel.count; i++) {
              l.push(linesModel.get(i).line);
          }
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
                           "tram": tram,
                           "lines": l
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
        text: qsTr("Lines")
      }

      TextField {
        id: newLineTextField
        width: Theme.itemSizeSmall * 4
        placeholderText: qsTr("Add line number")

        onTextChanged: {
          errorHighlight = false;
        }

        EnterKey.enabled: text.length > 0
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: {
          if(available_lines.hasOwnProperty(newLineTextField.text)) {
            newLineTextField.errorHighlight = false;
            if(available_lines[newLineTextField.text] == 1) {
              linesModel.append({"line": newLineTextField.text});
              available_lines[newLineTextField.text] = 0;
              newLineTextField.text = "";
            } else {
              newLineTextField.errorHighlight = true;
            }
          } else {
            newLineTextField.errorHighlight = true;
          }
        }
      }

      SilicaListView {
        id: linesListView
        width: parent.width
        property int maxHeight: 0
        height: maxHeight * linesModel.count

        model: linesModel

        delegate: ListItem {
          id: listItem
          height: lineLabel.height


          Label {
            id: lineLabel
            text: line
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
          }

          RemorseItem {
            id: remorse
          }

          onClicked: {
            var idx = index;
            remorse.execute(listItem, qsTr("Removing"), function() {
              available_lines[linesModel.get(idx).line] = 1;
              linesModel.remove(idx);
            });
          }

          Component.onCompleted: {
            linesListView.maxHeight = listItem.height > linesListView.maxHeight ? listItem.height : linesListView.maxHeight;
          }
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
