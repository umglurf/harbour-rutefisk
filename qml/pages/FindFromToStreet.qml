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
import Sailfish.Silica 1.0

Page {
  id: findFromToStreetPage
  property string fromID
  property string fromName
  property string toID
  property string toName
  property string streetID
  property string streetName
  property bool streetFrom: false
  property bool streetTo: false

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "MAIN_VIEW";
    }
  }

  Column {
    id: headerContainer
    width: parent.width

    PageHeader {
      title: qsTr("House numbers in %1").arg(streetName)
    }

    BusyIndicator {
      id: searchIndicator
      running: false
      visible: false
      size: BusyIndicatorSize.Small
    }

    Label {
      id: errorLabel
      visible: false
      color: Theme.highlightColor
      font.family: Theme.fontFamilyHeading
    }

  }

  SilicaListView {
    id: streetList
    model: streetModel
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.top: headerContainer.bottom

    delegate: ListItem {
      id: listItem
      Label {
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        text: Name
        font.capitalization: Font.Capitalize
        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
      }

      onClicked: {
        if(streetFrom) {
            if(toID) {
                pageStack.push(Qt.resolvedUrl("TravelFromTo.qml"), {
                                 "fromID": "x=" + X + ",y="  + Y,
                                 "fromName": streetName + " " + Name,
                                 "toID": findFromToStreetPage.toID,
                                 "toName": findFromToStreetPage.toName,
                               });

            } else {
                pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {
                                 "fromID": "x=" + X + ",y="  + Y,
                                 "fromName": streetName + " " + Name
                               });

            }
        } else if(streetTo){
            if(fromID) {
                pageStack.push(Qt.resolvedUrl("TravelFromTo.qml"), {
                                 "fromID": findFromToStreetPage.fromID,
                                 "fromName": findFromToStreetPage.fromName,
                                 "toID": "x=" + X + ",y="  + Y,
                                 "toName": streetName + " " + Name
                               });

            } else {
                pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {
                                 "toID": "x=" + X + ",y="  + Y,
                                 "toName": streetName + " " + Name
                               });

            }

        }
      }
    }

    Component.onCompleted: {
      streetModel.update();
    }
  }

  ListModel {
    id: streetModel

    function update() {
      searchIndicator.visible = true;
      searchIndicator.running = true;
      var xhr = new XMLHttpRequest()
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          streetModel.clear();
          for(var index=0; index < data['Houses'].length; index++) {
            streetModel.append(data['Houses'][index]);
          };
          searchIndicator.visible = false;
          searchIndicator.running = false;
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.visible = false;
          searchIndicator.running = false;
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting houses");
        }
      };
      xhr.open("GET", "http://reisapi.ruter.no/Street/GetStreet/" + streetID, true);
      xhr.send();
    }
  }
}
