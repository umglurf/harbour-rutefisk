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
import QtGraphicalEffects 1.0
import org.nemomobile.configuration 1.0
import Sailfish.Silica 1.0
import "../scripts/rutefisk.js" as RuteFisk

Page {
  id: showStopsPage
  property string tripID
  property var departureTime: new Date()
  property string departureID: "0"
  property string arrivalID: "0"
  property string lineNumber
  property string destination
  property BusyIndicator searchIndicator
  property Label errorLabel

  SilicaListView {
    anchors.fill: parent

    model: stopsModel

    header: Column {
      width: parent.width
      PageHeader {
        id: pageHeader
        title: qsTr("Stops for %1 %2").arg(lineNumber).arg(destination)
      }
      BusyIndicator {
        id: searchIndicator
        visible: false
        running: false
        size: BusyIndicatorSize.Small
        Component.onCompleted: {
          showStopsPage.searchIndicator = this;
        }
      }
      Label {
        visible: false
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
        Component.onCompleted: {
          showStopsPage.errorLabel = this;
        }
      }
    }

    delegate: ListItem {
      id: listItem
      contentHeight: contentColumn.height
      Column {
        width: parent.width
        id: contentColumn
        Label {
          text: qsTr("%1 (%2)").arg(Name).arg(runTime)
          color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
          font.bold: ID == departureID || ID == arrivalID
        }
        Row {
          width: parent.width
          Item {
            width: Theme.paddingLarge
            height: departureLabel.height
          }
          Label {
            visible: arrivalTime == departureTime
            text: arrivalTime
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
          }
          Label {
            id: arrivalLabel
            visible: arrivalTime != departureTime
            text: qsTr("Arrival: %1").arg(arrivalTime)
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall

          }
          Item {
            visible: arrivalTime != departureTime
            width: Theme.paddingMedium
            height: departureLabel.height
          }
          Label {
            id: departureLabel
            visible: arrivalTime != departureTime
            text: qsTr("Departure: %1").arg(departureTime)
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall

          }
        }
        Row {
          width: parent.width
          visible: Lines.count > 1

          Item {
            width: Theme.paddingLarge
            height: linesLabel.height
          }
          Label {
            id: linesLabel
            text: {
              var lines = [];
              for(var i=0; i < Lines.count; i++) {
                lines.push(Lines.get(i).Name);
              }
              return qsTr("Lines: %1").arg(lines.join(", "));
            }
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
          }
        }
        Row {
          width: parent.width
          visible: Zone.length > 0

          Item {
            width: Theme.paddingLarge
            height: zoneLabel.height
          }
          Label {
              id: zoneLabel
              text: qsTr("Zone %1").arg(Zone)
              color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
              font.pixelSize: Theme.fontSizeSmall
          }
        }
      }
      onClicked: {
        pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": ID, "stopName": Name, "linenumber": showStopsPage.lineNumber, "destination": showStopsPage.destination });
      }
      menu: ContextMenu {
        MenuItem {
          text: qsTr("Realtime info from %1").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": [ID], "stopName": Name });
          }
        }
        MenuItem {
          text: qsTr("Realtime info for %1 %2 from %3").arg(showStopsPage.lineNumber).arg(showStopsPage.destination).arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": ID, "stopName": Name, "linenumber": showStopsPage.lineNumber, "destination": showStopsPage.destination });
          }
        }
        MenuItem {
          text: qsTr("Travel from %1").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"fromID": ID, "fromName": Name});
          }
        }
        MenuItem {
          text: qsTr("Travel to %2").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"toID": ID, "toName": Name});
          }
        }
      }
    }
  }

  ListModel {
    id: stopsModel

    function update() {
      var xhr = new XMLHttpRequest();
      errorLabel.visible = false;
      searchIndicator.running = true;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          if(data['ReisError'] && data['ReisError'].hasOwnProperty('Description') ) {
            searchIndicator.running = false;
            errolLabel.visible = true;
            errorLabel.text = data['ReisError']['Description'];
            return;
          }
          stopsModel.clear();
          var startTime;
          var runTime;
          for(var index=0; index < data['Stops'].length; index++) {
            data['Stops'][index]['arrivalTime'] = RuteFisk.non_tz_date_parse(data['Stops'][index]['ArrivalTime']).toLocaleTimeString(Qt.locale(), "HH:mm");
            data['Stops'][index]['departureTime'] = RuteFisk.non_tz_date_parse(data['Stops'][index]['DepartureTime']).toLocaleTimeString(Qt.locale(), "HH:mm");
            if(index == 0) {
              startTime = RuteFisk.non_tz_date_parse(data['Stops'][index]['DepartureTime']);
              runTime = 0;
            } else {
              runTime = (RuteFisk.non_tz_date_parse(data['Stops'][index]['ArrivalTime']) - startTime) / 1000 / 60;
            }
            if(runTime < 60) {
              data['Stops'][index]['runTime'] = runTime.toFixed(0) + qsTr("min");
            } else {
              var hour = Math.floor((runTime / 60));
              var min = runTime - (hour * 60);
              data['Stops'][index]['runTime'] = hour + qsTr("h") + " " + min.toFixed(0) + qsTr("min");
            }
            stopsModel.append(data['Stops'][index]);
          };
          searchIndicator.running = false;
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.running = false;
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      var url = "http://reisapi.ruter.no/Trip/GetTrip/";
      url = url + tripID;
      url = url + "?time=" + departureTime.toLocaleDateString(Qt.locale(), "ddMMyyyy") + departureTime.toLocaleTimeString(Qt.locale(), "hhmmss");
      xhr.open("GET", url, true);
      xhr.send();
    }
  }

  Component.onCompleted: {
    stopsModel.update();
  }
}
