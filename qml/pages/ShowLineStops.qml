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
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

Page {
  id: showLineStopsPage
  property string stopID
  property string lineID
  property string lineNumber
  property string destination
  property BusyIndicator searchIndicator
  property Label errorLabel

  SilicaListView {
    anchors.fill: parent

    model: stopsModel

    header: Column {
      width: parent.width
      PageHeader {
        id: pageHeader
        title: qsTr("Stops for %1 %2").arg(lineNumber).arg(destination)
      }
      BusyIndicator {
        id: searchIndicator
        visible: false
        running: false
        size: BusyIndicatorSize.Small
        Component.onCompleted: {
          showLineStopsPage.searchIndicator = this;
        }
      }
      Label {
        visible: false
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
        Component.onCompleted: {
          showLineStopsPage.errorLabel = this;
        }
      }
    }

    delegate: ListItem {
      id: listItem
      contentHeight: contentColumn.height
      Column {
        width: parent.width
        id: contentColumn
        Label {
          text: Name
          color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
          font.bold: ID == stopID
        }
        Row {
          width: parent.width
          visible: Zone.length > 0

          Item {
            width: Theme.paddingLarge
            height: zoneLabel.height
          }
          Label {
              id: zoneLabel
              text: qsTr("Zone %1").arg(Zone)
              color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
              font.pixelSize: Theme.fontSizeSmall
          }
        }
      }
      onClicked: {
        pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": ID, "stopName": Name, "linenumber": showLineStopsPage.lineNumber, "destination": showLineStopsPage.destination });
      }
      menu: ContextMenu {
        MenuItem {
          text: qsTr("Realtime info from %1").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": [ID], "stopName": Name });
          }
        }
        MenuItem {
          text: qsTr("Realtime info for %1 %2 from %3").arg(showLineStopsPage.lineNumber).arg(showLineStopsPage.destination).arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": ID, "stopName": Name, "linenumber": showLineStopsPage.lineNumber, "destination": showLineStopsPage.destination });
          }
        }
        MenuItem {
          text: qsTr("Travel from %1").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"fromID": ID, "fromName": Name});
          }
        }
        MenuItem {
          text: qsTr("Travel to %2").arg(Name)
          onClicked: {
            pageStack.push(Qt.resolvedUrl("FindFromTo.qml"), {"toID": ID, "toName": Name});
          }
        }
      }
    }
  }

  ListModel {
    id: stopsModel

    function update() {
      var xhr = new XMLHttpRequest();
      errorLabel.visible = false;
      searchIndicator.running = true;
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          if(data.length == 0) {
            searchIndicator.running = false;
            errolLabel.visible = true;
            errorLabel.text = qsTr("Error getting stops");
            return;
          }
          if(data[0]['Name'].search(destination) != -1) {
              data = data.reverse();
          }
          stopsModel.clear();
          for(var index=0; index < data.length; index++) {
            stopsModel.append(data[index]);
          };
          searchIndicator.running = false;
        } else if(xhr.readyState == 4 && xhr.status == 0) {
          searchIndicator.running = false;
          errorLabel.visible = true;
          errorLabel.text = qsTr("Error getting stops");
        }
      };
      var url = "http://reisapi.ruter.no/Line/GetStopsByLineId/" + lineID;
      xhr.open("GET", url, true);
      xhr.send();
    }
  }

  Component.onCompleted: {
    stopsModel.update();
  }
}
