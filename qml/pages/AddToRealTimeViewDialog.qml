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

Dialog {
  id: addToRealTimeViewDialog
  property string stopID
  property string stopName
  property string lineNumber
  property string destination

  ConfigurationValue {
    id: realTimeViewsConfig
    key: "/apps/rutefisk/realtimeviews"
    defaultValue: "[]"
  }

  ConfigurationGroup {
      id: realTimeViewGroup
      path: "/apps/rutefisk/realtimeview"
  }

  ListModel {
    id: realTimeViewsModel
    dynamicRoles: true
    Component.onCompleted: {
      update();
    }

    function update() {
      realTimeViewsModel.clear();
      var views = JSON.parse(realTimeViewsConfig.value);
      for(var i=0; i < views.length; i++) {
        append({"name": views[i]});
      }
    }
  }

  Column {
      width: parent.width

      DialogHeader { }

      TextField {
          id: nameField
          width: parent.width
          placeholderText: qsTr("Name of new realtime view")
          label: qsTr("Name")
          visible: false
      }

      ComboBox {
        id: nameBox
        label: qsTr("Realtime view")
        currentIndex: -1

        menu: ContextMenu {
            MenuItem { text: qsTr("New realtime view") }
            Repeater {
                model: realTimeViewsModel

                MenuItem {
                    text: name
                }
            }
        }
        onValueChanged: {
            if(currentIndex == 0) {
                nameField.visible = true;
            } else {
                nameField.visible = false;
            }
        }
      }
  }

  onAccepted: {
      var name = nameBox.value;
      if(nameBox.currentIndex == 0) {
          name = nameField.text;
          var views = JSON.parse(realTimeViewsConfig.value);
          views.push(name);
          realTimeViewsConfig.value = JSON.stringify(views);
      }
      var items = JSON.parse(realTimeViewGroup.value(name, "[]"));
      for(var i = 0; i < items.length; i++) {
          if(items[i]['stopID'] == stopID &&
                  items[i]['stopName'] == stopName &&
                  items[i]['lineNumber'] == lineNumber &&
                  items[i]['destination'] == destination) {
              return;
          }
      };
      var item = {
          "stopID": stopID,
          "stopName": stopName,
          "lineNumber": lineNumber,
          "destination": destination
      };
      items.push(item);
      realTimeViewGroup.setValue(name, JSON.stringify(items));
  }

}
