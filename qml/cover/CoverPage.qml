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

CoverBackground {
    id: cover
    //anchors.fill: parent
    //transparent: true

    Image {
      anchors.fill: parent
      source: "harbour-ruter.png";
      x: Theme.paddingLarge
      y: Theme.paddingMedium + Theme.paddingSmall
      width: parent.width - 2*x
      opacity: 0.8
    }


    SilicaListView {
        id: realTimeList
        model: departuresModel

        property real itemHeight: Theme.itemSizeExtraSmall

        clip: true
        interactive: false
        x: Theme.paddingMedium
        y: Theme.paddingMedium + Theme.paddingSmall
        width: parent.width - 2*x
        height: 4*itemHeight + 2*Theme.paddingSmall
        spacing: Theme.paddingSmall

        delegate:  Column {
          width: parent.width
          Component.onCompleted: realTimeList.itemHeight = height

          Item {
            width: parent.width
            height: Theme.paddingSmall
          }
          Label {
            text: line
            color: Theme.primaryColor
            truncationMode: TruncationMode.Fade
          }
          Label {
            text: departure
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.primaryColor
            truncationMode: TruncationMode.Fade
          }
        }
    }

    ListModel {
        id: departuresModel

        function update(stopID) {
          var xhr = new XMLHttpRequest();
          xhr.onreadystatechange = function() {
            if(xhr.readyState == 4 && xhr.status == 200) {
              var now = new Date();
              var travels = {};
              var lines_sorted = [];
              var data = JSON.parse(xhr.responseText);
              var l = data.length;
              for(var index=0; index < l; index++) {
                var line = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
                if(!travels.hasOwnProperty(line)) {
                  lines_sorted.push(line);
                  travels[line] = {};
                  travels[line]['line'] = line;
                  travels[line]['departures'] = [];
                }
                travels[line]['departures'].push(new Date(data[index]['MonitoredVehicleJourney']['MonitoredCall']['ExpectedArrivalTime']));
              }
              lines_sorted.sort();
              var now = new Date();
              for(var index=0; index < lines_sorted.length; index++) {
                travels[lines_sorted[index]]['departures'].sort();
                var departures = travels[lines_sorted[index]]['departures'];
                var departure = "";
                for(var i=0; i < departures.length && i < 3; i++) {
                  var departure_time = departures.shift();
                  var timestr;
                  if(departure_time - now.getTime() < (1000 * 60 * 10)) { // 10 minutes, 1000 usec * 60 sec * 10
                    if(departure_time - now.getTime() < (1000 * 60)) { // 1 minute, 1000 usec * 60 sec
                      timestr = ((departure_time - now.getTime()) / 1000 ).toFixed(0) + qsTr("sec");
                    } else {
                      timestr = ((departure_time - now.getTime()) / 1000 / 60 ).toFixed(0) + qsTr("min");
                    }
                  } else {
                    timestr = departure_time.toLocaleTimeString(Qt.locale(), "HH:mm");
                  }
                  departure = departure + timestr + " ";
                }
                travels[lines_sorted[index]]['departure'] = departure;
                departuresModel.append(travels[lines_sorted[index]]);
              }
            }
          }
          xhr.open("GET", "http://reisapi.ruter.no/StopVisit/GetDepartures/" + stopID, true);
          xhr.send();
        }
    }

    Timer {
        id: departureTimer
        interval: 10000
        repeat: true
        running: false
        triggeredOnStart: true

        onTriggered: {
            if(pageStack.currentPage.stopID) {
              departuresModel.clear();
              for(var i=0; i < pageStack.currentPage.stopID.length; i++) {
                departuresModel.update(pageStack.currentPage.stopID[i]);
              }
            } else {
                departuresModel.clear();
            }
        }
    }

    onStatusChanged: {
        if(cover.status == Cover.Active) {
            departureTimer.stop();
            departureTimer.start();
        } else {
            departureTimer.stop();
            departuresModel.clear();
        }
    }
}


