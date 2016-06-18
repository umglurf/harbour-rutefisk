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

Page {
  id: realTimeViewPage
  property string name
  property var stops
  property bool autorefresh: realTimeAutoRefresh.value
  property BusyIndicator searchIndicator
  property Label errorLabel

  ConfigurationValue {
    id: realTimeViewsConfig
    key: "/apps/rutefisk/realtimeviews"
    defaultValue: "[]"
  }
  ConfigurationValue {
    id: realTimeAutoRefresh
    key: "/apps/rutefisk/realtime/autorefresh"
    defaultValue: false
  }
  ConfigurationValue {
    id: realTimeAutoRefreshInterval
    key: "/apps/rutefisk/realtime/autorefreshinterval"
    defaultValue: 30
  }

  SilicaListView {
    id: realTimeViewList
    anchors.fill: parent
    model: realTimeViewModel


    PullDownMenu {
      width: parent.width
      MenuItem {
          text: qsTr("Settings")
          onClicked: {
              pageStack.push(Qt.resolvedUrl("Settings.qml"));
          }
      }
      MenuItem {
        text: autorefresh ? qsTr("Stop auto refresh") : qsTr("Auto Refresh");
        onClicked: {
          if(autorefresh) {
              realTimeViewTimer.stop();
          } else {
              realTimeViewTimer.start();
          }
          autorefresh = !autorefresh;
        }
      }
      MenuItem {
        text: qsTr("Refresh");
        onClicked: {
          for(var stopIndex=0; stopIndex < realTimeViewPage.stops.length; stopIndex++) {
            realTimeViewModel.update(realTimeViewPage.stops[stopIndex]);
          }
        }
      }
    }

    header: Column {
      id: col
      width: parent.width

      PageHeader {
        title: name
      }

      BusyIndicator {
        id: searchIndicator
        visible: false
        running: false
        size: BusyIndicatorSize.Small
        Component.onCompleted: {
          realTimeViewPage.searchIndicator = this;
        }
      }

      Label {
        id: errorLabel
        visible: false
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
        Component.onCompleted: {
          realTimeViewPage.errorLabel = this;
        }
      }

    }

    delegate: ListItem {
        id: listItem
        width: parent.width
        contentHeight: contentColumn.height
        Column {
          id: contentColumn
          width: parent.width
          Row {
            width: parent.width
            Item {
              width: Theme.paddingSmall
              height: lineDataColumn.height
            }
            Column {
              id: lineDataColumn
              width: parent.width - Theme.paddingSmall
              Row {
                TransportIcon {
                  width: lineLabel.height
                  height: lineLabel.height
                  transportation: RuteFisk.lines[lineRef] === undefined ? "3" : RuteFisk.lines[lineRef]
                }
                Label {
                  id: lineLabel
                  text: linenumber + " " + destination
                  color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
              }
              Row {
                visible: false
                width: parent.width
                Item {
                  width: Theme.paddingLarge
                  height: Theme.paddingMedium
                }
                Label {
                  color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                  font.pixelSize: Theme.fontSizeExtraSmall
                  text: {
                    var dev = [];
                    for(var key in deviations) {
                      if(deviations.hasOwnProperty(key)) {
                        dev.push(deviations[key]);
                      }
                    }
                    if(dev.length > 0) {
                      parent.visible = true;
                      return dev.join("\n");
                    } else {
                      return "";
                    }
                  }
                }
              }
              Row {
                width: parent.width
                Item {
                  width: Theme.paddingLarge
                  height: departuresGrid.height
                }

                Grid {
                  id: departuresGrid
                  property int maxwidth: Theme.itemSizeSmall
                  width: parent.width - Theme.paddingLarge
                  columnSpacing: Theme.paddingMedium
                  columns: width / maxwidth

                  Repeater {
                    model: departures

                    delegate: Label {
                      text: timestring
                      color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                      font.pixelSize: Theme.fontSizeSmall

                      Component.onCompleted: {
                        if(width > departuresGrid.maxwidth) {
                          departuresGrid.maxwidth = width;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        onClicked: {
          pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": stopID, "stopName": realTimePage.stopName, "linenumber": linenumber, "destination": destination });
        }
        menu: ContextMenu {
          MenuItem {
            text: qsTr("Realtime for %1 %2").arg(linenumber).arg(destination)
            onClicked: {
              pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": stopID, "stopName": stopName, "linenumber": linenumber, "destination": destination });
            }
          }

          MenuItem {
            text: qsTr("Show all stops for %1 %2").arg(linenumber).arg(destination)
            onClicked: {
              pageStack.push(Qt.resolvedUrl("ShowLineStops.qml"), {
                               "stopID": stopID,
                               "lineID": lineRef,
                               "lineNumber": linenumber,
                               "destination": destination
                             });
            }
          }

          MenuItem {
            text: qsTr("Add to realtime view")
            onClicked: {
              var dialog = pageStack.push(Qt.resolvedUrl("AddToRealTimeViewDialog.qml"), { "stopID": stopID, "stopName": stopName, "lineNumber": linenumber, "destination": destination } );
            }
          }

        }
    }
    Timer {
      id: realTimeViewTimer
      interval: realTimeAutoRefreshInterval.value * 1000
      repeat: true
      triggeredOnStart: false

      onTriggered: {
        for(var stopIndex=0; stopIndex < realTimeViewPage.stops.length; stopIndex++) {
          realTimeViewModel.update(realTimeViewPage.stops[stopIndex]);
        }
      }
    }
    Component.onCompleted: {
      realTimeViewModel.clear();
      for(var stopIndex=0; stopIndex < realTimeViewPage.stops.length; stopIndex++) {
        realTimeViewModel.update(realTimeViewPage.stops[stopIndex]);
      }
      if(autorefresh) {
        realTimeViewTimer.start();
      }
    }
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "REALTIME_CUSTOM_VIEW";
      applicationWindow.coverPage.stops = realTimeViewPage.stops;
      if(autorefresh) {
        realTimeViewTimer.start();
      }
    } else if(status == PageStatus.Deactivating) {
      realTimeViewTimer.stop();
    }
  }

  ListModel {
    id: realTimeViewModel

    function update(stop) {
      RuteFisk.get_lines();
      searchIndicator.visible = true;
      searchIndicator.running = true;
      errorLabel.visible = false;
      var xhr = new XMLHttpRequest()
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          var now = new Date();
          var line = {};
          line['stopName'] = stop['stopName']
          line['deviations'] = {};
          line['departures'] = [];
          var data = JSON.parse(xhr.responseText);
          for(var index=0; index < data.length; index++) {
            var lineNumber = data[index]['MonitoredVehicleJourney']['PublishedLineName']
            var destination = data[index]['MonitoredVehicleJourney']['DestinationName'];
            if(lineNumber != stop['lineNumber'] || destination != stop['destination']) {
              continue;
            }
            line['line'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
            line['lineColor'] = "#" + data[index]['Extensions']['LineColour'];
            line['linenumber'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'];
            line['lineRef'] = data[index]['MonitoredVehicleJourney']['LineRef'];
            line['destination'] = data[index]['MonitoredVehicleJourney']['DestinationName'];
            line['origin'] = data[index]['MonitoredVehicleJourney']['OriginName'] ? data[index]['MonitoredVehicleJourney']['OriginName'] : "";
            line['stopID'] = stop['stopID'];
            for(var deviationindex=0; deviationindex < data[index]['Extensions']['Deviations'].length; deviationindex++) {
              line['deviations'][data[index]['Extensions']['Deviations'][deviationindex]['ID']] = data[index]['Extensions']['Deviations'][deviationindex]['Header'];
            }
            var departure = RuteFisk.non_tz_date_parse(data[index]['MonitoredVehicleJourney']['MonitoredCall']['ExpectedArrivalTime']);
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
            line['departures'].push({"timestring": timestr});
          }
          var updated = false;
          for(var mindex = 0; mindex < realTimeViewModel.count; mindex++) {
            if(realTimeViewModel.get(mindex).line == line['line']) {
              realTimeViewModel.remove(mindex, 1);
              realTimeViewModel.insert(mindex, line);
              updated = true;
              break;
            }
          }
          if(!updated) {
            realTimeViewModel.append(line);
          }
          searchIndicator.visible = false;
          searchIndicator.running = false;
        } else if(xhr.readyState == 4) {
          searchIndicator.visible = false;
          searchIndicator.running = false;
          realTimeLineModel.clear();
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stop information");
        }
      };
      var url = "http://reisapi.ruter.no/StopVisit/GetDepartures/";
      url = url + stop['stopID'];
      url = url + '?linenames=' + stop['lineNumber']
      xhr.open("GET", url, true);
      xhr.send();
    }
  }
}
