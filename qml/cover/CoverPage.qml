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
import org.nemomobile.configuration 1.0
import Sailfish.Silica 1.0
import "../scripts/rutefisk.js" as RuteFisk

CoverBackground {
  id: cover
  state: "MAIN_VIEW"
  property var stopID
  property string linenumber
  property string destination
  property ListModel travelModel
  property string fromName
  property string toName

  ConfigurationValue {
    id: coverPageAlwaysRefresh
    key: "/apps/rutefisk/coverpage/alwaysrefresh"
    defaultValue: true
  }
  ConfigurationValue {
    id: coverPageAutoRefreshInterval
    key: "/apps/rutefisk/coverpage/autorefreshinterval"
    defaultValue: 30
  }

  Image {
    id: coverImage
    source: "cover.svg";
    anchors.fill: parent
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
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
      }
      Label {
        text: departure
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
      }
    }
  }

  ListModel {
    id: departuresModel

    function update(stopID, linenumber, destination) {
      var xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          var now = new Date();
          var travels = {};
          var lines_sorted = [];
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          for(var index=0; index < l; index++) {
            var linenr = data[index]['MonitoredVehicleJourney']['PublishedLineName'];
            var dest = data[index]['MonitoredVehicleJourney']['DestinationName'];
            var line = linenr + " " + dest;
            if(linenumber > 0) {
              if(linenr != linenumber || dest != destination) {
                continue;
              }
            }

            if(!travels.hasOwnProperty(line)) {
              lines_sorted.push(line);
              travels[line] = {};
              travels[line]['line'] = line;
              travels[line]['departures'] = [];
            }
            travels[line]['departures'].push(RuteFisk.non_tz_date_parse(data[index]['MonitoredVehicleJourney']['MonitoredCall']['ExpectedArrivalTime']));
          }
          lines_sorted.sort();
          var now = new Date();
          for(var index=0; index < lines_sorted.length; index++) {
            travels[lines_sorted[index]]['departures'].sort(function(a, b) { return a.getTime() - b.getTime() });
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
            var updated = false;
            for(var mindex = 0; mindex < departuresModel.count && departuresModel.count > 0; mindex++) {
              if(departuresModel.get(mindex)['line'] == travels[lines_sorted[index]]['line']) {
                departuresModel.set(mindex, travels[lines_sorted[index]]);
                updated = true;
                break;
              }
            }
            if(!updated) {
              departuresModel.append(travels[lines_sorted[index]]);
            }
          }
        }
      }
      var url = "http://reisapi.ruter.no/StopVisit/GetDepartures/";
      url = url + stopID;
      if(linenumber > 0) {
        url = url + '?linenames=' + linenumber;
      }
      xhr.open("GET", url, true);
      xhr.send();
    }
  }

  Timer {
    id: departureTimer
    interval: coverPageAutoRefreshInterval.value * 1000
    repeat: true
    running: false
    triggeredOnStart: true

    onTriggered: {
      if(state == "REALTIME_LINE_VIEW") {
        departuresModel.update(stopID, linenumber, destination);
      } else {
        for(var i=0; i < stopID.length; i++) {
          departuresModel.update(stopID[i], 0, "");
        }
      }
    }
  }

  SilicaListView {
    id: travelList
    model: travelModel

    property real itemHeight: Theme.itemSizeExtraSmall

    clip: true
    interactive: false
    x: Theme.paddingMedium
    y: Theme.paddingMedium + Theme.paddingSmall
    width: parent.width - 2*x
    height: parent.height - 2*Theme.paddingSmall
    spacing: Theme.paddingSmall

    header: Column {
      width: parent.width

      Label {
        text: fromName
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.primaryColor
      }
      Label {
        text: toName
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.primaryColor
      }
    }
    delegate:  Column {
      width: parent.width

      Item {
        width: parent.width
        height: Theme.paddingSmall
      }
      Label {
        id: travelTimeLabel
        text: departure + " - " + arrival
        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
      }
    }
  }

  Component.onCompleted: {
    applicationWindow.coverPage = this;
  }

  states: [
    State {
      name: "MAIN_VIEW"
      StateChangeScript {
        name: "stopTimerClearModel"
        script: {
          departureTimer.stop();
          departuresModel.clear();
        }
      }
      PropertyChanges {
        target: coverImage;
        visible: true
      }
      PropertyChanges {
        target: realTimeList;
        visible: false
      }
      PropertyChanges {
        target: travelList;
        visible: false
      }
    },
    State {
      name: "REALTIME_VIEW"
      PropertyChanges {
        target: coverImage;
        visible: false
      }
      PropertyChanges {
        target: realTimeList;
        visible: true
      }
      PropertyChanges {
        target: travelList;
        visible: false
      }
      StateChangeScript {
        name: "restartTimer"
        script: departureTimer.restart();
      }
      StateChangeScript {
        name: "clearModel"
        script: departuresModel.clear();
      }
    },
    State {
      name: "REALTIME_LINE_VIEW"
      extend: "REALTIME_VIEW"
    },
    State {
      name: "TRAVEL_VIEW"
      PropertyChanges {
        target: coverImage;
        visible: false
      }
      PropertyChanges {
        target: realTimeList;
        visible: false
      }
      PropertyChanges {
        target: travelList;
        visible: true
      }
      StateChangeScript {
        name: "stopTimer"
        script: departureTimer.stop();
      }
    }

  ]

  onStatusChanged: {
    if(state == "REALTIME_VIEW" || state == "REALTIME_LINE_VIEW") {
      if(!coverPageAlwaysRefresh.value) {
        if(cover.status == Cover.Activating) {
          departureTimer.restart();
        } else if (cover.status == Cover.Deactivating){
          departureTimer.stop();
        }
      }
    }
  }
}


