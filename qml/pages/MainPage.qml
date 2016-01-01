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
    id: mainpage
    property string searchString

    onSearchStringChanged: {
        placesModel.update();
    }

    Column {
        id: headerContainer
        width: mainpage.width

        PageHeader {
            title: qsTr("Search places")
        }


        SearchField {
            id: searchField
            width: parent.width
            placeholderText: qsTr("Search")

            Binding {
                target: mainpage
                property: "searchString"
                value: searchField.text
            }
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

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Realtime info")
                    visible: PlaceType == 'Stop' || PlaceType == 'Area'
                    onClicked: show_realtime()
                }
                MenuItem {
                    text: qsTr("Travel from here")
                }
                MenuItem {
                    text: qsTr("Travel to here")
                }
            }

            onClicked: {
                show_realtime();
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

        function update() {
            xhr.abort();
            xhr.onreadystatechange = function() {
                if(xhr.readyState == 4 && xhr.status == 200) {
                    var data = JSON.parse(xhr.responseText);
                    var l = data.length;
                    placesModel.clear();
                    for(var index=0; index < l; index++) {
                        placesModel.append(data[index]);
                    };
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

