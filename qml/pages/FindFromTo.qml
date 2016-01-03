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
  id: findFromToPage
  property string searchString
  property string fromID
  property string toID
  property string fromtoname

  onSearchStringChanged: {
    placesModel.update();
  }

  Column {
    id: headerContainer
    width: findFromToPage.width

    PageHeader {
      title: qsTr("Travel") + " " + (fromID ? qsTr("from") : qsTr("to")) + " " + fromtoname
    }


    SearchField {
      id: searchField
      width: parent.width
      placeholderText: fromID ? qsTr("Search destination") : qsTr("Search start")

      Binding {
        target: findFromToPage
        property: "searchString"
        value: searchField.text
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
        text: Name
        font.capitalization: Font.Capitalize
        color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
      }

      onClicked: {
        var fromID;
        var fromName;
        var toID;
        var toName;
        if(findFromToPage.fromID) {
          fromID = findFromToPage.fromID
          fromName = findFromToPage.fromtoname
          toID = ID
          toName = Name
        } else {
          fromID = ID
          fromName = Name
          toID = findFromToPage.toID
          toName = findFromToPage.fromtoname
        }
        pageStack.push(Qt.resolvedUrl("TravelFromTo.qml"), {
                           "fromID": fromID, "fromName": fromName,
                           "toID": toID, "toName": toName
                       });
      }
    }

    Component.onCompleted: {
      searchField.forceActiveFocus();
    }
  }


  ListModel {
    id: placesModel
    property var xhr: new XMLHttpRequest()

    function update() {
      xhr.abort();
      errorLabel.visible = false
      xhr.onreadystatechange = function() {
        if(xhr.readyState == 4 && xhr.status == 200) {
          errorLabel.visible = false;
          var data = JSON.parse(xhr.responseText);
          var l = data.length;
          placesModel.clear();
          for(var index=0; index < l; index++) {
            placesModel.append(data[index]);
          };
        } else if(xhr.readyState == 4 && xhr.status == 0) {
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
  }
}
