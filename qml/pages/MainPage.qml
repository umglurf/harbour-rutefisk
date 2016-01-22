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
import "../scripts/rutefisk.js" as RuteFisk

Page {
  id: mainpage
  property string searchString
  property Label errorLabel
  property SearchField searchField
  property BusyIndicator searchIndicator
  property BusyIndicator gpsSearchIndicator
  property Row textSearch
  property Column gpsSearch
  property int gpsOffset: 300
  property int gpsUpdateInterval: 3000

  states: [
    State {
      name: "TEXT_SEARCH"
      PropertyChanges {
        target: textSearch
        visible: true
      }
      PropertyChanges {
        target: gpsSearch
        visible: false
      }
      PropertyChanges {
        target: gpsSearchIndicator
        running: false
      }
      StateChangeScript {
        name: "stopGps"
        script: {
          positionSource.stop();
        }
      }
    },
    State {
      name: "GPS_SEARCH"
      PropertyChanges {
        target: textSearch
        visible: false
      }
      PropertyChanges {
        target: gpsSearch
        visible: true
      }
      PropertyChanges {
        target: gpsSearchIndicator
        running: true
      }
      StateChangeScript {
        name: "startGps"
        script: {
          positionSource.start();
          searchField.focus = false;
        }
      }
    }
  ]

  onSearchStringChanged: {
    placesModel.update();
  }

  onGpsOffsetChanged: {
    positionSource.do_search();
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      if(state  == "GPS_SEARCH") {
        positionSource.start();
      }
      if(applicationWindow.coverPage) {
        applicationWindow.coverPage.state = "MAIN_VIEW";
      }
    } else if(status == PageStatus.Deactivating) {
      positionSource.stop();
    }
  }

  PositionSource {
    id: positionSource
    active: false
    updateInterval: mainpage.gpsUpdateInterval

    function do_search() {
      if(position.latitudeValid && position.longitudeValid && active) {
        var xy = new Array(2);
        var zone = Math.floor ((position.coordinate.longitude + 180.0) / 6) + 1;
        zone = GPSConvert.LatLonToUTMXY (GPSConvert.DegToRad (position.coordinate.latitude), GPSConvert.DegToRad (position.coordinate.longitude), zone, xy);
        placesModel.update_gps(Math.floor(xy[0]),Math.floor(xy[1]));
      }
    }

    onPositionChanged: {
      do_search();
    }
  }

  SilicaFlickable {
    anchors.fill: parent

    PullDownMenu {
      MenuItem {
          text: qsTr("Settings")
          onClicked: {
              pageStack.push(Qt.resolvedUrl("Settings.qml"));
          }
      }
      MenuItem {
        text: qsTr("Start GPS search")
        onClicked: {
          if(mainpage.state == "TEXT_SEARCH") {
            mainpage.state = "GPS_SEARCH";
            text = qsTr("Stop GPS search");
          } else if(mainpage.state == "GPS_SEARCH") {
            mainpage.state = "TEXT_SEARCH";
            text = qsTr("Start GPS search");
          }
        }
      }
      MenuItem {
          text: qsTr("Favorites")
          onClicked: {
              pageStack.push(Qt.resolvedUrl("Favorites.qml"));
          }
      }
    }

    Column {
      id: headerContainer
      width: parent.width

      PageHeader {
        title: qsTr("Ruter travel information")
      }

      Row {
        width: parent.width
        SearchField {
          id: searchField
          width: parent.width - searchIndicator.width - Theme.paddingSmall
          placeholderText: qsTr("Search stop or street")
          inputMethodHints: Qt.ImhNone

          Binding {
            target: mainpage
            property: "searchString"
            value: searchField.text
          }
          Component.onCompleted: {
              mainpage.searchField = this;
          }
        }
        BusyIndicator {
          id: searchIndicator
          running: false
          size: BusyIndicatorSize.Small
          //anchors.verticalCenter: parent.verticalCenter
          Component.onCompleted: {
            mainpage.searchIndicator = this
          }
        }
        Component.onCompleted: {
          mainpage.textSearch = this;
        }
      }

      Column {
        width: parent.width
        visible: false
        BusyIndicator {
          anchors.horizontalCenter: parent.horizontalCenter
          running: false
          size: BusyIndicatorSize.Small
          Component.onCompleted: {
            mainpage.gpsSearchIndicator = this;
          }
        }
        Slider {
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          minimumValue: 1000
          maximumValue: 30000
          stepSize: 1000.0
          label: qsTr("GPS update interval")
          valueText: (value / 1000).toFixed(0) + qsTr("s")
          onValueChanged: {
            mainpage.gpsUpdateInterval = value.toFixed(0);
          }
          Component.onCompleted: {
            value = mainpage.gpsUpdateInterval;
          }
        }
        Slider {
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          minimumValue: 0
          maximumValue: 2000
          stepSize: 50.0
          label: qsTr("GPS search grid size")
          valueText: value + qsTr("meters")
          onValueChanged: {
            mainpage.gpsOffset = value.toFixed(0);
          }
          Component.onCompleted: {
            value = mainpage.gpsOffset;
          }
        }
        Component.onCompleted: {
          mainpage.gpsSearch = this;
        }
      }

      Label {
        id: errorLabel
        visible: false
        Component.onCompleted: {
          mainpage.errorLabel = this;
        }
      }

      Item {
          height: Theme.paddingLarge;
      }

    }

    SilicaListView {
      id: placesList
      model: placesModel
      anchors.top:  headerContainer.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right

      delegate: ListItem {
        id: listItem
        Label {
          x: Theme.horizontalPageMargin
          anchors.verticalCenter: parent.verticalCenter
          text: Name
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
                pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name, "streetFrom": true});
              } else {
                pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"fromID": ID, "fromName": Name});
              }
            }
          }
          MenuItem {
            text: qsTr("Travel to here")
            onClicked: {
              if(PlaceType == "Street") {
                pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name, "streetTo": true});
              } else {
                pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"toID": ID, "toName": Name});
              }
            }
          }
        }

        onClicked: {
          if(PlaceType == "Street") {
            pageStack.push(Qt.resolvedUrl("FindFromToStreet.qml"), {"streetID": ID, "streetName": Name, "streetFrom": true});
          } else {
            show_realtime();
          }
        }

        function show_realtime() {
          if(PlaceType == "Stop") {
            pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": [ID], "stopName": Name });
          } else if(PlaceType == "Area") {
            var id = [];
            for(var i=0; i < Stops.count; i++) {
              id.push(Stops.get(i)['ID']);
            }
            pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": id, "stopName": Name });
          }
        }
      }
    }
  }

  Component.onCompleted: {
    searchField.forceActiveFocus();
    state = "TEXT_SEARCH";
  }

  ListModel {
    id: placesModel
    dynamicRoles: true
    property var xhr: new XMLHttpRequest()

    function update() {
      xhr.abort();
      errorLabel.visible = false;
      searchIndicator.running = true;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          placesModel.clear();
          for(var index=0; index < l; index++) {
            placesModel.append(data[index]);
          };
          RuteFisk.add_district(placesModel);
          searchIndicator.running = false;
        } else if(xhr.readyState == 4) {
          searchIndicator.running = false;
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      if(searchString == "") {
        placesModel.clear();
        searchIndicator.running = false;
      } else {
        xhr.open("GET", "http://reisapi.ruter.no/Place/GetPlaces/" + searchString.trim(), true);
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
          RuteFisk.add_district(placesModel);
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      var url = "http://reisapi.ruter.no/Place/GetStopsByArea/?";
      url = url + "xmin=" + (x-mainpage.gpsOffset);
      url = url + "&xmax=" + (x+mainpage.gpsOffset);
      url = url + "&ymin=" + (y-mainpage.gpsOffset);
      url = url + "&ymax=" + (y+mainpage.gpsOffset);
      xhr.open("GET", url, true);
      xhr.send();
    }
  }
}

