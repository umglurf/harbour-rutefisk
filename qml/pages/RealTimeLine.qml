/*
This file is part of harbour-ruter.

    harbour-ruter is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    harbour-ruter is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with harbour-ruter.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
  id: realTimeLinePage
  property string stopID
  property string stopName
  property string linenumber
  property string destination
  property bool autorefresh: false
  property BusyIndicator searchIndicator

  SilicaGridView {
      id: realTimeLineList
      anchors.fill: parent
      cellWidth: Theme.itemSizeSmall

      model: realTimeLineModel

      header: Column {
          width: parent.width
          PageHeader {
            id: pageHeader
            title: qsTr("%1 %2 from %3").arg(linenumber).arg(destination).arg(stopName)
          }
          BusyIndicator {
            id: searchIndicator
            visible: false
            running: false
            size: BusyIndicatorSize.Small
            Component.onCompleted: {
                realTimeLinePage.searchIndicator = this;
            }
          }
      }

      PullDownMenu {
        MenuItem {
          text: qsTr("Auto Refresh");
          onClicked: {
            autorefresh = true
            realTimeLineTimer.start();
          }
        }
        MenuItem {
          text: qsTr("Refresh");
          onClicked: {
              realTimeLineModel.update();
          }
        }
      }

      delegate: Label {
        Component.onCompleted: realTimeLineList.cellHeight = height
        text: departure
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
      }
  }

  Timer {
    id: realTimeLineTimer
    interval: 30000
    repeat: true
    triggeredOnStart: false

    onTriggered: {
      if(Qt.application.state == Qt.ApplicationActive) {
        realTimeLineModel.update();
      }
    }
  }

  Component.onCompleted: {
      realTimeLineModel.update();
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "REALTIME_LINE_VIEW";
      applicationWindow.coverPage.stopID = realTimeLinePage.stopID;
      applicationWindow.coverPage.linenumber = realTimeLinePage.linenumber;
      applicationWindow.coverPage.destination = realTimeLinePage.destination;
    }
  }

  ListModel {
    id: realTimeLineModel

    function update() {
      searchIndicator.visible = true;
      searchIndicator.running = true;
      var xhr = new XMLHttpRequest()
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          realTimeLineModel.clear();
          var now = new Date();
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          for(var index=0; index < l; index++) {
            var departuredata = {};
            var line = data[index]['MonitoredVehicleJourney']['PublishedLineName']
            var destination = data[index]['MonitoredVehicleJourney']['DestinationName'];
            if(line != realTimeLinePage.linenumber || destination != realTimeLinePage.destination) {
                continue;
            }
            departuredata['line'] = line;
            departuredata['destination'] = destination;
            var departure = new Date(data[index]['MonitoredVehicleJourney']['MonitoredCall']['ExpectedArrivalTime']);
            var timestr;
            if(departure.getTime() - now.getTime() < (1000 * 60 * 10)) { // 10 minutes, 1000 usec * 60 sec * 10
              if(departure.getTime() - now.getTime() < (1000 * 60)) { // 1 minute, 1000 usec * 60 sec
                timestr = ((departure.getTime() - now.getTime()) / 1000 ).toFixed(0) + qsTr("sec");
              } else {
                timestr = ((departure.getTime() - now.getTime()) / 1000 / 60 ).toFixed(0) + qsTr("min");
              }
            } else {
              timestr = departure.toLocaleTimeString(Qt.locale(), "HH:mm");
            }
            departuredata['departure'] = timestr;

            realTimeLineModel.append(departuredata);
          }
          searchIndicator.visible = false;
          searchIndicator.running = false;
        } else if(xhr.readyState == 4) {
          searchIndicator.visible = false;
          searchIndicator.running = false;
          realTimeLineModel.clear();
          realTimeLineModel.append({"departure": qsTr("Error getting stop information")});
        }
      };
      xhr.open("GET", "http://reisapi.ruter.no/StopVisit/GetDepartures/" + realTimeLinePage.stopID, true);
      xhr.send();
    }
  }
}
