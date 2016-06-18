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

Page {
  id: realTimeViews
  property Label errorLabel

  ConfigurationValue {
    id: realTimeViewsConfig
    key: "/apps/rutefisk/realtimeviews"
    defaultValue: "[]"
  }
  ConfigurationGroup {
      id: realTimeViewGroup
      path: "/apps/rutefisk/realtimeview"
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "MAIN_VIEW";
      realTimeViewsModel.update();
    }
  }

  SilicaListView {
    anchors.fill: parent

    header: Column {
      width: parent.width
      PageHeader {
        id: pageHeader
        title: qsTr("Realtime Views")
      }
      Label {
        visible: false
        color: Theme.highlightColor
        font.family: Theme.fontFamilyHeading
        Component.onCompleted: {
          realTimeViews.errorLabel = this;
        }
      }
    }

    model: ListModel {
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

    delegate: ListItem {
      id: realTimeViewItem
      RemorseItem {
        id: remorse
      }
      Label {
        text: name
      }
      onClicked: {
        var stops = JSON.parse(realTimeViewGroup.value(name, "[]"));
        pageStack.push(Qt.resolvedUrl("RealTimeView.qml"), {
                         "name": name,
                         "stops": stops
                       });
      }
      menu: ContextMenu {
        MenuItem {
          text: qsTr("Remove")
          onClicked: {
            var idx = index;
            remorse.execute(realTimeViewItem, "Removing", function() {
              try {
                var views = JSON.parse(realTimeViewsConfig.value);
                for(var i=0; i < views.length; i++) {
                  if(views[i] == name ) {
                    views.splice(i, 1);
                  };
                }
                realTimeViewsConfig.value = JSON.stringify(views);
                realTimeViewsModel.remove(idx);
              } catch(err) {
                realTimeViewsModel.clear();
                errorLabel.visible = true;
                errorLabel.text = qsTr("Error removing item");
              }
            });
          }
        }
      }
    }
  }
}
