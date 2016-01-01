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
  property var stopID
  property string stopName
  property string line

  SilicaListView {
      anchors.fill: parent
      model: realTimeLineModel

      header: {
          PageHeader {
              title: qsTr("Travels from") + " " + stopName
          }
      }
  }

  Component.onCompleted: {
      realTimeModel.update();
  }

  ListModel {
    id: realTimeLineModel

    function update() {
      var xhr = new XMLHttpRequest()
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          var now = new Date();
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          for(var index=0; index < l; index++) {
            var departuredata = {};
            var line = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
            if(line != realTimeLinePage.line) {
                continue;
            }
            departuredata['line'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'];
            departuredata['destination'] = data[index]['MonitoredVehicleJourney']['DestinationName'];
            departuredata['origin'] = data[index]['MonitoredVehicleJourney']['OriginName'] ? data[index]['MonitoredVehicleJourney']['OriginName'] : "";
            var departure = new Date(data[index]['MonitoredVehicleJourney']['MonitoredCall']['AimedArrivalTime']);
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
            departuredata['departure_aimed'] = timestr;

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
            departuredata['departure_expected'] = timestr;

            realTimeLineModel.append(departuredata);
          }
        }
      };
      xhr.open("GET", "http://reisapi.ruter.no/StopVisit/GetDepartures/" + realTimeLinePage.stopID, true);
      xhr.send();
    }
  }
}
