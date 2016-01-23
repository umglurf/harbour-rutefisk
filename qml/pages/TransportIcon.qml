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

Item {
  property string transportation
  visible: transportation != "0" && transportation != "3"

  Image {
    id: lineIcon
    anchors.fill: parent
    source: {
      if(transportation == "0") { //walking
        return "";
      } else if(transportation == "1") { //airportbus
        return "../icons/bus.svg"
      } else if(transportation == "2") { //bus
        return "../icons/bus.svg";
      } else if(transportation == "3") { //dummy
        return "";
      } else if(transportation == "4") { //airporttrain
        return "../icons/train.svg";
      } else if(Transportation == "5") { //boat
        return "../icons/boat.svg";
      } else if(Transportation == "6") { //train
        return "../icons/train.svg";
      } else if(Transportation == "7") { //tram
        return "../icons/tram.svg";
      } else if(Transportation == "8") { //metro
        return "../icons/metro.svg";
      }
    }
  }
  ColorOverlay {
    anchors.fill: lineIcon
    source: lineIcon
    color: Theme.highlightColor
  }
}
