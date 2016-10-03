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
  id: favorites
  property Label errorLabel

  ConfigurationValue {
    id: favoritesConfig
    key: "/apps/rutefisk/favorites"
    defaultValue: "[]"
  }

  onStatusChanged: {
    if(status == PageStatus.Active) {
      applicationWindow.coverPage.state = "MAIN_VIEW";
      var favorites = JSON.parse(favoritesConfig.value);
      if(favorites.length > 0) {
        info.visible = false;
        list.visible = true;
        favoritesModel.update();
      } else {
        info.visible = true;
        list.visible = false;
      }
    }
  }

  SilicaFlickable {
      id: info
      anchors.fill: parent
      visible: false
      PageHeader {
        id: pageHeader
        title: qsTr("Favorites")
      }
      Row {
        anchors.top: pageHeader.bottom
        width: parent.width
        Item {
          width: Theme.paddingSmall
          height: Theme.paddingSmall
        }
        TextArea {
          width: parent.width - Theme.paddingSmall * 2
          readOnly: true
          wrapMode: Text.WordWrap
          text: qsTr("You have no favorites defined. You add a journey or a realtime stop to the favorites by using the Add to favorites on the pull down menu.")
        }
      }
  }

  SilicaListView {
      id: list
      anchors.fill: parent
      visible: false

      header: Column {
          width: parent.width
          PageHeader {
            id: pageHeader
            title: qsTr("Favorites")
          }
          Label {
              visible: false
              color: Theme.highlightColor
              font.family: Theme.fontFamilyHeading
              Component.onCompleted: {
                  favorites.errorLabel = this;
              }
          }
      }

      model: ListModel {
          id: favoritesModel
          dynamicRoles: true
          Component.onCompleted: {
              update();
          }

          function update() {
              favoritesModel.clear();
              var favorites = JSON.parse(favoritesConfig.value);
              for(var i=0; i < favorites.length; i++) {
                var val = JSON.parse(favorites[i]);
                if(val['type'] == 'realTime') {
                  val['stopID'] = JSON.stringify(val['stopID']); //avoid array getting lost in ListModel
                } else if(val['type'] == 'journey') {
                    // add lines if this favourite has been save before lines was available
                    if(!val.hasOwnProperty('lines')) {
                        val['lines'] = "[]";
                    } else {
                        val['lines'] = JSON.stringify(val['lines']); //avoid array getting lost in ListModel
                    }
                }

                append(val);
              }
          }
      }

      delegate: ListItem {
          id: favoriteItem
          RemorseItem {
              id: remorse
          }
          Row {
            width: parent.width
            Item {
                width: Theme.paddingMedium
                height: Theme.paddingSmall
            }
            Label {
              text: {
                if(type == "journey") {
                  fromName + " - " + toName;
                } else if(type == "realTime") {
                  stopName;
                } else if(type == "realTimeLine") {
                  qsTr("%1 %2 from %3").arg(linenumber).arg(destination).arg(stopName);
                }
              }
            }
          }
          onClicked: {
              if(type == "journey") {
                var l = JSON.parse(lines);
                pageStack.push(Qt.resolvedUrl("TravelFromTo.qml"), {
                                 "fromID": fromID,
                                 "fromName": fromName,
                                 "toID": toID,
                                 "toName": toName,
                                 "isafter": isafter,
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
                                 "tram": tram,
                                 "lines": l
                               });
              } else if(type == "realTime") {
                var s = JSON.parse(stopID);
                pageStack.push(Qt.resolvedUrl("RealTime.qml"), { "stopID": s, "stopName": stopName});
              } else if(type == "realTimeLine") {
                pageStack.push(Qt.resolvedUrl("RealTimeLine.qml"), { "stopID": stopID, "stopName": stopName, "linenumber": linenumber, "destination": destination });
              }
          }
          menu: ContextMenu {
              MenuItem {
                  text: qsTr("Remove")
                  onClicked: {
                      var idx = index;
                      remorse.execute(favoriteItem, "Removing", function() {
                          try {
                            var favorites = JSON.parse(favoritesConfig.value);
                            for(var i=0; i < favorites.length; i++) {
                              var val = JSON.parse(favorites[i]);
                              if(val['type'] == 'journey' && val['fromID'] == fromID && val['toID'] == toID ) {
                                  favorites.splice(i, 1);
                              } else if(val['type'] == 'realTime') {// && val['stopID'].join("-") == stopID.join("-")) {
                                  var eq = true;
                                  for(var j = 0; j > val['stopID'].length; j++) {
                                      if(val['stopID'][j] != stopID.get(j)) {
                                          eq = false;
                                      }
                                  }
                                  if(eq) {
                                    favorites.splice(i, 1);
                                  };
                              } else if(val['type'] == 'realTimeLine' && val['stopID'] == stopID && val['linenumber'] == linenumber && val['destination'] == destination) {
                                  favorites.splice(i, 1);
                              }
                            }
                            favoritesConfig.value = JSON.stringify(favorites);
                            favoritesModel.remove(idx);
                            if(favorites.length == 0) {
                              info.visible = true;
                              list.visible = false;
                            }
                          } catch(err) {
                              favoritesModel.clear();
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
