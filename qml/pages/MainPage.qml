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
import QtPositioning 5.2
import Sailfish.Silica 1.0
import "../scripts/gpsconvert.js" as GPSConvert

Page {
  id: mainpage
  property string searchString

  onSearchStringChanged: {
    stop_gps_search();
    placesModel.update();
  }

  onStatusChanged: {
    if(status == PageStatus.Active && applicationWindow.coverPage) {
      applicationWindow.coverPage.state = "MAIN_VIEW";
    }
  }

  function start_gps_search() {
      gpsIndicator.running = true;
      positionSource.start();
      gpsSearchTimer.restart();

  }

  function stop_gps_search() {
      gpsIndicator.running = false;
      positionSource.stop();
      gpsSearchTimer.stop();
  }

  Timer {
      id: gpsSearchTimer
      interval: 60000
      repeat: false
      triggeredOnStart: false

      onTriggered: {
          stop_gps_search();
      }
  }

  PositionSource {
    id: positionSource
    active: false
    updateInterval: 1000

    onPositionChanged: {
      if(position.latitudeValid && position.longitudeValid) {
        var xy = new Array(2);
        var zone = Math.floor ((position.coordinate.longitude + 180.0) / 6) + 1;
        zone = GPSConvert.LatLonToUTMXY (GPSConvert.DegToRad (position.coordinate.latitude), GPSConvert.DegToRad (position.coordinate.longitude), zone, xy);
        placesModel.update_gps(Math.floor(xy[0]),Math.floor(xy[1]));
      }
    }
  }

  Column {
    id: headerContainer
    width: mainpage.width

    PageHeader {
      title: qsTr("Ruter travel information")
    }


    Row {
      width: parent.width
      SearchField {
        id: searchField
        width: parent.width - searchIndicator.width - Theme.paddingSmall
        placeholderText: qsTr("Search stop or street")

        Binding {
          target: mainpage
          property: "searchString"
          value: searchField.text
        }
      }
      BusyIndicator {
        id: searchIndicator
        running: false
        size: BusyIndicatorSize.Small
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      Button {
        text: qsTr("Search using gps")
        onClicked: {
            start_gps_search();
        }
      }
      BusyIndicator {
        id: gpsIndicator
        running: false
        size: BusyIndicatorSize.Small
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Label {
      id: errorLabel
      visible: false
    }

  }

  SilicaListView {
    id: placesList
    model: placesModel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.top: headerContainer.bottom

    delegate: ListItem {
      id: listItem
      Label {
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        text: Name + (PlaceType == "Street" ? " (" + District + ")" : "" )
        font.capitalization: Font.Capitalize
        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
      }

      menu: ContextMenu {
        MenuItem {
          text: qsTr("Realtime info")
          visible: PlaceType == 'Stop' || PlaceType == 'Area'
          onClicked: show_realtime()
        }
        MenuItem {
          text: qsTr("Travel from here")
          onClicked: {
            if(PlaceType == "Street") {
              pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name + " (" + District + ")", "streetFrom": true});
            } else {
              pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"fromID": ID, "fromName": Name});
            }
          }
        }
        MenuItem {
          text: qsTr("Travel to here")
          onClicked: {
            if(PlaceType == "Street") {
              pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name + " (" + District + ")", "streetTo": true});
            } else {
              pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"toID": ID, "toName": Name});
            }
          }
        }
      }

      onClicked: {
        if(PlaceType == "Street") {
          pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name + " (" + District + ")", "streetFrom": true});
        } else {
          show_realtime();
        }
      }

      function show_realtime() {
        if(PlaceType == "Stop") {
          pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": [ID], "stopName": Name, "autorefresh": false});
        } else if(PlaceType == "Area") {
          var id = [];
          for(var i=0; i < Stops.count; i++) {
            id.push(Stops.get(i)['ID']);
          }
          pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": id, "stopName": Name, "autorefresh": false});
        }
      }
    }

    Component.onCompleted: {
      searchField.forceActiveFocus();
    }
  }

  ListModel {
    id: placesModel
    property var xhr: new XMLHttpRequest()
    property int gpsOffset: 500

    function update() {
      xhr.abort();
      errorLabel.visible = false
      searchIndicator.running = true
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          placesModel.clear();
          for(var index=0; index < l; index++) {
            placesModel.append(data[index]);
          };
          searchIndicator.running = false
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.running = false
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      if(searchString == "") {
        placesModel.clear();
      } else {
        xhr.open("GET", "http://reisapi.ruter.no/Place/GetPlaces/" + searchString, true);
        xhr.send();
      }
    }
    function update_gps(x,y) {
      xhr.abort();
      errorLabel.visible = false;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          if(data.length == 0) {
              return;
          }
          placesModel.clear();
          for(var index=0; index < data.length; index++) {
            placesModel.append(data[index]);
          };
          stop_gps_search();
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          stop_gps_search();
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      var url = "http://reisapi.ruter.no/Place/GetStopsByArea/?";
      url = url + "xmin=" + (x-gpsOffset);
      url = url + "&xmax=" + (x+gpsOffset);
      url = url + "&ymin=" + (y-gpsOffset);
      url = url + "&ymax=" + (y+gpsOffset);
      xhr.open("GET", url, true);
      xhr.send();
    }
  }
}

