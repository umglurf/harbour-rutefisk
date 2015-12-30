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
  id: realTimePage
  property string stopID
  property string stopName
  property bool autorefresh

  SilicaFlickable {
    id: realTimeList
    anchors.fill: parent
    contentHeight: col.height + Theme.paddingLarge


    PullDownMenu {
      MenuItem {
        text: qsTr("Auto Refresh");
        onClicked: {
            autorefresh = true
            realTimeTimer.start();
        }
      }
      MenuItem {
        text: qsTr("Refresh");
        onClicked: {
          pageStack.replace(Qt.resolvedUrl("RealTime.qml"), { "stopID": stopID, "stopName": stopName, "autorefresh": autorefresh}, PageStackAction.Immediate);
        }
      }
    }

    Column {
      id: col
      width: parent.width

      PageHeader {
        title: "Travels from " + stopName
      }

      Column {
        width: parent.width

        Repeater {
          id: realTimePlatforms
          model: realTimeModel

          delegate: Column {
            width: parent.width

            Label {
              id: platformLabel
              text: qsTr("Platform") + " " + name
              color: Theme.highlightColor
            }

            Repeater {
              id: realTimeLines

              Component.onCompleted: {
                model.update(lines);
              }

              model: ListModel {

                function update(lines) {
                  this.clear();
                  var lines_sorted = [];
                  for(var line in lines) {
                    if(lines.hasOwnProperty(line)) {
                      lines_sorted.push(line);
                    }
                  }
                  lines_sorted.sort();
                  for(var i=0; i < lines_sorted.length; i++) {
                    this.append(lines[lines_sorted[i]]);
                  }
                }
              }

              delegate: Column {
                width: parent.width

                Label {
                  id: lineLabel
                  text: linenumber + " " + destination
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.highlightColor
                }

                Grid {
                  width: parent.width
                  columnSpacing: Theme.fontSizeExtraSmall
                  columns: width / Theme.itemSizeSmall

                  Repeater {
                    id: realTimeDepartures

                    Component.onCompleted: {
                      model.update(departures);
                    }

                    model: ListModel {

                      function update(departures) {
                        this.clear();
                        var departures_sorted = [];
                        for(var departure in departures) {
                          if(departures.hasOwnProperty(departure)) {
                            departures_sorted.push(departure);
                          }
                        }
                        departures_sorted.sort();
                        for(var i=0; i < departures_sorted.length; i++) {
                          this.append(departures[departures_sorted[i]]);
                        }
                      }
                    }

                    delegate:  Label {
                      text: timestring
                      font.pixelSize: Theme.fontSizeExtraSmall
                      color: Theme.secondaryHighlightColor
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    Timer {
        id: realTimeTimer
        interval: 10000
        repeat: false
        triggeredOnStart: false

        onTriggered: {
          if(Qt.application.state == Qt.ApplicationActive) {
            pageStack.replace(Qt.resolvedUrl("RealTime.qml"), { "stopID": stopID, "stopName": stopName, "autorefresh": autorefresh}, PageStackAction.Immediate);
          } else {
              realTimeTimer.repeat = true;
              realTimeTimer.interval = 30000;
              realTimeTimer.start();
          }
        }
    }

    Component.onCompleted: {
      realTimeModel.update();
      if(autorefresh) {
        realTimeTimer.start();
      }
    }
  }

  ListModel {
    id: realTimeModel
    property var xhr: new XMLHttpRequest()

    function update() {
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          var now = new Date();
          var travels = {};
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          for(var index=0; index < l; index++) {
            var line = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
            var platform = data[index]['MonitoredVehicleJourney']['MonitoredCall']['DeparturePlatformName'];

            if(!travels.hasOwnProperty(platform)) {
              travels[platform] = {};
              travels[platform]['name'] = platform
              travels[platform]['lines'] = {}
            }
            if(!travels[platform]['lines'].hasOwnProperty(line)) {
              travels[platform]['lines'][line] = {}
              travels[platform]['lines'][line]['linenumber'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'];
              travels[platform]['lines'][line]['destination'] = data[index]['MonitoredVehicleJourney']['DestinationName'];
              travels[platform]['lines'][line]['origin'] = data[index]['MonitoredVehicleJourney']['OriginName'] ? data[index]['MonitoredVehicleJourney']['OriginName'] : "";
              travels[platform]['lines'][line]['departures'] = {}
            }
            var departure = new Date(data[index]['MonitoredVehicleJourney']['MonitoredCall']['ExpectedArrivalTime']);
            var timestr;
            if(departure.getTime() - now.getTime() < (1000 * 60 * 10)) { // 10 minutes, 1000 usec * 60 sec * 10
              if(departure.getTime() - now.getTime() < (1000 * 60)) { // 1 minute, 1000 usec * 60 sec
                timestr = ((departure.getTime() - now.getTime()) / 1000 ).toFixed(0) + qsTr("sec");
              } else {
                timestr = ((departure.getTime() - now.getTime()) / 1000 / 60 ).toFixed(2) + qsTr("min");
              }
            } else {
              timestr = departure.toLocaleTimeString(Qt.locale(), "HH:mm");
            }
            travels[platform]['lines'][line]['departures'][departure.getTime()] = data[index]['MonitoredVehicleJourney']['MonitoredCall'];
            travels[platform]['lines'][line]['departures'][departure.getTime()]['timestring'] = timestr;
          }
          var platforms = []
          for(var platform in travels) {
            if(travels.hasOwnProperty(platform)) {
              platforms.push(platform);
            }
          }
          platforms.sort();
          for(var i=0; i < platforms.length; i++) {
            realTimeModel.append(travels[platforms[i]]);
          }
        }
      };
      xhr.open("GET", "http://reisapi.ruter.no/StopVisit/GetDepartures/" + realTimePage.stopID, true);
      xhr.send();
    }
  }
}

