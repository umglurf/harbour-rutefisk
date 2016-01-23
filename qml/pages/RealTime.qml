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
  id: realTimePage
  property var stopID
  property string stopName
  property bool autorefresh: realTimeAutoRefresh.value

  ConfigurationValue {
    id: favoritesConfig
    key: "/apps/rutefisk/favorites"
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

  SilicaFlickable {
    id: realTimeList
    anchors.fill: parent
    contentHeight: col.height + Theme.paddingLarge


    PullDownMenu {
      MenuItem {
          text: qsTr("Settings")
          onClicked: {
              pageStack.push(Qt.resolvedUrl("Settings.qml"));
          }
      }
      MenuItem {
        text: qsTr("Add to favorites");
        onClicked: {
          var favorite = {
            "type": "realTime",
            "stopID": stopID,
            "stopName": stopName
          };
          try {
            var favorites = JSON.parse(favoritesConfig.value);
            for(var i=0; i < favorites.length; i++) {
              var val = JSON.parse(favorites[i]);
              if(val['type'] == 'realTime' && val['stopID'].join("-") == stopID.join("-")) {
                return;
              }
            }
            favorites.push(JSON.stringify(favorite));
            favoritesConfig.value = JSON.stringify(favorites);
          } catch(err) {
            errorLabel.visible = true;
            errorLabel.text = qsTr("Error adding favorite");
          }
        }
      }
      MenuItem {
        text: autorefresh ? qsTr("Stop auto refresh") : qsTr("Auto Refresh");
        onClicked: {
          if(autorefresh) {
              realTimeTimer.stop();
          } else {
              realTimeTimer.start();
          }
          autorefresh = !autorefresh;
        }
      }
      MenuItem {
        text: qsTr("Refresh");
        onClicked: {
          for(var stopIndex=0; stopIndex < realTimePage.stopID.length; stopIndex++) {
            realTimeModel.update(realTimePage.stopID[stopIndex]);
          }
        }
      }
    }

    Column {
      id: col
      width: parent.width

      PageHeader {
        title: qsTr("Travels from %1").arg(stopName)
      }

      BusyIndicator {
        id: searchIndicator
        visible: false
        running: false
        size: BusyIndicatorSize.Small
      }

      Label {
        id: errorLabel
        visible: false
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
      }

      Column {
        width: parent.width
        Repeater {
          model: realTimeModel

          delegate: Item {
            width: realTimePage.width
            height: platformHeader.height + lineView.height

            SectionHeader {
              id: platformHeader
              text: qsTr("Platform %1").arg(name)
            }

            SilicaListView {
              id: lineView
              anchors.top: platformHeader.bottom
              anchors.right: parent.right
              anchors.left: parent.left
              model: lines
              interactive: false
              height: Theme.paddingMedium

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
                Component.onCompleted: {
                  lineView.height = lineView.height + listItem.height;
                }
                Component.onDestruction: {
                  lineView.height = lineView.height - listItem.height;
                }

                onClicked: {
                  pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": stopID, "stopName": realTimePage.stopName, "linenumber": linenumber, "destination": destination });
                }
              }
            }
          }
        }
      }
    }

    Timer {
      id: realTimeTimer
      interval: realTimeAutoRefreshInterval.value * 1000
      repeat: true
      triggeredOnStart: false

      onTriggered: {
        for(var stopIndex=0; stopIndex < realTimePage.stopID.length; stopIndex++) {
          realTimeModel.update(realTimePage.stopID[stopIndex]);
        }
      }
    }

    Component.onCompleted: {
      realTimeModel.clear();
      for(var stopIndex=0; stopIndex < realTimePage.stopID.length; stopIndex++) {
        realTimeModel.update(realTimePage.stopID[stopIndex]);
      }
      if(autorefresh) {
        realTimeTimer.start();
      }
    }
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "REALTIME_VIEW";
      applicationWindow.coverPage.stopID = stopID;
      if(autorefresh) {
          realTimeTimer.start();
      }
    } else if(status == PageStatus.Deactivating) {
        realTimeTimer.stop();
    }
  }

  ListModel {
    id: realTimeModel

    function update(stopID) {
      RuteFisk.get_lines();
      var xhr = new XMLHttpRequest()
      searchIndicator.visible = true;
      searchIndicator.running = true;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          var now = new Date();
          var travels = {};
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          var lines = {};
          for(var index=0; index < l; index++) {
            var line = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
            var platform = data[index]['MonitoredVehicleJourney']['MonitoredCall']['DeparturePlatformName'];

            if(!travels.hasOwnProperty(platform)) {
              travels[platform] = {};
              travels[platform]['name'] = platform;
              travels[platform]['lines'] = [];
            }
            var lineIndex = 0;
            if(lines.hasOwnProperty(platform+line)) {
              lineIndex = lines[platform+line];
            } else {
              lineIndex = travels[platform]['lines'].length;
              lines[platform+line] = lineIndex;
              var line = {};
              line['line'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'] + data[index]['MonitoredVehicleJourney']['DestinationName'];
              line['lineColor'] = "#" + data[index]['Extensions']['LineColour'];
              line['linenumber'] = data[index]['MonitoredVehicleJourney']['PublishedLineName'];
              line['lineRef'] = data[index]['MonitoredVehicleJourney']['LineRef'];
              line['destination'] = data[index]['MonitoredVehicleJourney']['DestinationName'];
              line['origin'] = data[index]['MonitoredVehicleJourney']['OriginName'] ? data[index]['MonitoredVehicleJourney']['OriginName'] : "";
              line['departures'] = [];
              line['stopID'] = stopID
              line['deviations'] = {};
              travels[platform]['lines'].push(line);
            }
            for(var deviationindex=0; deviationindex < data[index]['Extensions']['Deviations'].length; deviationindex++) {
              travels[platform]['lines'][lineIndex]['deviations'][data[index]['Extensions']['Deviations'][deviationindex]['ID']] = data[index]['Extensions']['Deviations'][deviationindex]['Header'];
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
            travels[platform]['lines'][lineIndex]['departures'].push({"timestring": timestr});
          }
          var platforms = []
          for(var platform in travels) {
            if(travels.hasOwnProperty(platform)) {
              platforms.push(platform);
            }
          }
          platforms.sort();
          for(var i=0; i < platforms.length; i++) {
            var updated = false;
            for(var mindex = 0; mindex < realTimeModel.count; mindex++) {
                if(realTimeModel.get(mindex).name == travels[platforms[i]]['name']) {
                    realTimeModel.get(mindex).lines.clear();
                    for(var linesIndex = 0; linesIndex < travels[platforms[i]]['lines'].length; linesIndex++) {
                      realTimeModel.get(mindex).lines.append(travels[platforms[i]]['lines'][linesIndex]);
                    }
                    updated = true;
                    break;
                }
            }
            if(!updated) {
              realTimeModel.append(travels[platforms[i]]);
            }
          }
          searchIndicator.visible = false;
          searchIndicator.running = false;
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.visible = false;
          searchIndicator.running = false;
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stop information");
        }
      };
      xhr.open("GET", "http://reisapi.ruter.no/StopVisit/GetDepartures/" + stopID, true);
      xhr.send();
    }
  }
}

