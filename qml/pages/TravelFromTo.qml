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
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

Page {
  id: travelFromToPage
  property bool error: false
  property string errorstring

  property string fromID
  property string fromName
  property string toID
  property string toName
  property var date: new Date()
  property var time: new Date()
  property real changemargin: 2
  property real changepunish: 8
  property real walkingfactor: 100
  property real maxwalkingminutes: 20
  property bool airportbus: true
  property bool airporttrain: true
  property bool bus: true
  property bool train: true
  property bool boat: true
  property bool metro: true
  property bool tram: true
  property BusyIndicator searchIndicator

  SilicaFlickable {
    anchors.fill: parent
    visible: error

    Column {
      PageHeader {
        title: "An error occured"
      }

      Label {
        text: errorstring
      }
    }
  }

  SilicaListView {
    anchors.fill: parent
    visible: !error

    header: Column {
      width: parent.width
      PageHeader {
        id: pageHeader
        title: qsTr("Journey information")
      }
      Label {
        text: qsTr("From") + " " + fromName
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
      }
      Label {
        text: qsTr("To") + " " + toName
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
      }
      BusyIndicator {
        id: searchIndicator
        running: false
        size: BusyIndicatorSize.Small
        Component.onCompleted: {
            travelFromToPage.searchIndicator = this;
        }
      }
    }

    PullDownMenu {
      MenuItem {
        text: qsTr("Search options");
        onClicked: {
          pageStack.push(Qt.resolvedUrl("TravelFromToOptions.qml"), {
                           "fromID": fromID,
                           "fromName": fromName,
                           "toID": toID,
                           "toName": toName,
                           "date": date,
                           "time": time,
                           "changemargin": changemargin,
                           "changepunish": changepunish,
                           "walkingfactor": walkingfactor,
                           "maxwalkingminutes": maxwalkingminutes,
                           "airportbus": airportbus,
                           "airporttrain": airporttrain,
                           "bus": bus,
                           "train": train,
                           "boat": boat,
                           "metro": metro,
                           "tram": tram
                         });
        }
      }
    }


    model: travelModel

    delegate: ListItem {
      height: linesItemColumn.height
      width: parent.width

      onClicked: {
          linesColumn.visible = !linesColumn.visible;
          linesGrid.visible = !linesGrid.visible;
      }

      Column {
        id: linesItemColumn
        width: parent.width
        Label {
          id: travelTimeLabel
          text: departure + " - " + arrival + " (" + traveltime + ")"
        }
        Grid {
          id: linesGrid
          property int maxwidth: Theme.itemSizeSmall
          width: parent.width
          columnSpacing: Theme.paddingMedium
          columns: width / maxwidth

          Repeater {

            model: Stages

            delegate: Row {
              Component.onCompleted: {
                if(width > linesGrid.maxwidth) {
                  linesGrid.maxwidth = width
                }
              }

              Label {
                id: lineLabel
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                text: walking ? qsTr("Walking") : LineName
              }
              Item {
                height: lineLabel.height
                width: lineLabel.height
                Image {
                  id: lineIcon
                  anchors.fill: parent
                  Component.onCompleted: {
                    if(Transportation == "0") { //walking
                      parent.visible = false
                    } else if(Transportation == "1") { //airportbus
                      source = "../icons/bus.svg"
                    } else if(Transportation == "2") { //bus
                      source = "../icons/bus.svg"
                    } else if(Transportation == "3") { //dummy
                      parent.visible = false
                    } else if(Transportation == "4") { //airporttrain
                      source = "../icons/train.svg"
                    } else if(Transportation == "5") { //boat
                      source = "../icons/boat.svg"
                    } else if(Transportation == "6") { //train
                      source = "../icons/train.svg"
                    } else if(Transportation == "7") { //tram
                      source = "../icons/tram.svg"
                    } else if(Transportation == "8") { //metro
                      source = "../icons/metro.svg"
                    }
                  }
                }
                ColorOverlay {
                  anchors.fill: lineIcon
                  source: lineIcon
                  color: Theme.highlightColor
                }
              }
            }
          }
        }

        Column {
          id: linesColumn
          visible: false

          Repeater {
            model: Stages

            delegate: Column {
              Row {
                Item {
                  visible: !walking
                  height: lineLabel.height
                  width: lineLabel.height
                  Image {
                    id: lineIcon
                    anchors.fill: parent
                    Component.onCompleted: {
                      if(Transportation == "0") { //walking
                        parent.visible = false
                      } else if(Transportation == "1") { //airportbus
                        source = "../icons/bus.svg"
                      } else if(Transportation == "2") { //bus
                        source = "../icons/bus.svg"
                      } else if(Transportation == "3") { //dummy
                        parent.visible = false
                      } else if(Transportation == "4") { //airporttrain
                        source = "../icons/train.svg"
                      } else if(Transportation == "5") { //boat
                        source = "../icons/boat.svg"
                      } else if(Transportation == "6") { //train
                        source = "../icons/train.svg"
                      } else if(Transportation == "7") { //tram
                        source = "../icons/tram.svg"
                      } else if(Transportation == "8") { //metro
                        source = "../icons/metro.svg"
                      }
                    }
                  }
                  ColorOverlay {
                    anchors.fill: lineIcon
                    source: lineIcon
                    color: Theme.highlightColor
                  }
                }
                Label {
                  id: lineLabel
                  visible: !walking
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.highlightColor
                  text: LineName + " " + Destination + " (" + traveltime + ")"
                }
              }

              Row {
                Item {
                  visible: !walking
                  height: departureLabel.height
                  width: departureLabel.height * 2 + Theme.paddingSmall
                }
                Label {
                  id: departureLabel
                  visible: !walking
                  font.pixelSize: Theme.fontSizeExtraSmall
                  color: Theme.highlightColor
                  Component.onCompleted: {
                      if(!walking) {
                        text = DepartureStop['Name'] + ": " + departure
                      }
                  }
                }
              }

              Row {
                Item {
                  visible: !walking
                  height: arrivalLabel.height
                  width: arrivalLabel.height * 2 + Theme.paddingSmall
                }
                Label {
                  id: arrivalLabel
                  visible: !walking
                  font.pixelSize: Theme.fontSizeExtraSmall
                  color: Theme.highlightColor
                  Component.onCompleted: {
                    if(!walking) {
                      text = ArrivalStop['Name'] + ": " + arrival
                    }
                  }
                }
              }

              Row {
                Item {
                  visible: walking
                  height: walkingLabel.height
                  width: walkingLabel.height
                }
                Label {
                  id: walkingLabel
                  visible: walking
                  font.pixelSize: Theme.fontSizeSmall
                  color: Theme.highlightColor
                  text: qsTr("Walking %L1").arg(traveltime)
                }
              }
            }
          }
        }
      }
    }
  }

  Component.onCompleted: {
    travelModel.update();
  }

  ListModel {
    id: travelModel
    property var xhr: new XMLHttpRequest()

    function update() {
      searchIndicator.visible = true;
      searchIndicator.running = true;
      xhr.abort();
      error = false;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          error = false;
          var data = JSON.parse(xhr.responseText);
          travelModel.clear();
          for(var index=0; index < data['TravelProposals'].length; index++) {
            var arrival = new Date(data['TravelProposals'][index]['ArrivalTime']);
            data['TravelProposals'][index]['arrival'] = arrival.toLocaleTimeString(Qt.locale(), "HH:mm");
            var departure = new Date(data['TravelProposals'][index]['DepartureTime']);
            data['TravelProposals'][index]['departure'] = departure.toLocaleTimeString(Qt.locale(), "HH:mm");
            var traveltime = ( arrival.getTime() - departure.getTime() ) / 1000 / 60;
            if(traveltime < 60) {
              data['TravelProposals'][index]['traveltime'] = traveltime + qsTr("min");
            } else {
              var hour = Math.floor((traveltime / 60));
              var min = traveltime - (hour * 60);
              data['TravelProposals'][index]['traveltime'] = hour + qsTr("h") + " " + min + qsTr("min");
            }
            for(var stageindex=0; stageindex < data['TravelProposals'][index]['Stages'].length; stageindex++) {
              if(data['TravelProposals'][index]['Stages'][stageindex].hasOwnProperty('WalkingTime')) {
                data['TravelProposals'][index]['Stages'][stageindex]['walking'] = true
              } else {
                data['TravelProposals'][index]['Stages'][stageindex]['walking'] = false
              }
              var arrival = new Date(data['TravelProposals'][index]['Stages'][stageindex]['ArrivalTime']);
              data['TravelProposals'][index]['Stages'][stageindex]['arrival'] = arrival.toLocaleTimeString(Qt.locale(), "HH:mm");
              var departure = new Date(data['TravelProposals'][index]['Stages'][stageindex]['DepartureTime']);
              data['TravelProposals'][index]['Stages'][stageindex]['departure'] = departure.toLocaleTimeString(Qt.locale(), "HH:mm");
              var traveltime = ( arrival.getTime() - departure.getTime() ) / 1000 / 60;
              if(traveltime < 60) {
                data['TravelProposals'][index]['Stages'][stageindex]['traveltime'] = traveltime + qsTr("min");
              } else {
                var hour = Math.floor((traveltime / 60));
                var min = traveltime - (hour * 60);
                data['TravelProposals'][index]['Stages'][stageindex]['traveltime'] = hour + qsTr("h") + " " + min + qsTr("min");
              }
            }


            travelModel.append(data['TravelProposals'][index]);
          };
          searchIndicator.visible = false;
          searchIndicator.running = false;
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.visible = false;
          searchIndicator.running = false;
          error = true;
          errorstring = qsTr("Error getting travel search result");
        }
      };
      var url = "http://reisapi.ruter.no/Travel/GetTravels/?"
      url = url + "fromplace=" + travelFromToPage.fromID;
      url = url + "&toplace=" + travelFromToPage.toID;
      url = url + "&isafter=false";
      url = url + "&time=" + travelFromToPage.date.toLocaleDateString(Qt.locale(), "ddMMyyyy") + travelFromToPage.time.toLocaleTimeString(Qt.locale(), "hhmmss");
      url = url + "&changemargin=" + travelFromToPage.changemargin;
      url = url + "&changepunish=" + travelFromToPage.changepunish;
      url = url + "&walkingfactor=" + travelFromToPage.walkingfactor;
      url = url + "&maxwalkingminutes=" + travelFromToPage.maxwalkingminutes;
      var transport = [];
      if(travelFromToPage.airportbus) {
        transport.push("AirportBus");
      }
      if(travelFromToPage.airporttrain) {
        transport.push("AirportTrain");
      }
      if(travelFromToPage.bus) {
        transport.push("Bus");
      }
      if(travelFromToPage.train) {
        transport.push("Train");
      }
      if(travelFromToPage.boat) {
        transport.push("Boat");
      }
      if(travelFromToPage.metro) {
        transport.push("Metro");
      }
      if(travelFromToPage.tram) {
        transport.push("Tram");
      }
      url = url + "&transporttypes=" + transport.join(",");
      xhr.open("GET", url, true);
      xhr.send();
    }
  }
}
