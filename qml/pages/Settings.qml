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
  id: settingsPage

  ConfigurationValue {
    id: realTimeAutoRefresh
    key: "/apps/rutefisk/realtime/autorefresh"
    defaultValue: false
  }
  ConfigurationValue {
    id: realTimeAutoRefreshInterval
    key: "/apps/rutefisk/realtime/autorefreshinterval"
    defaultValue: 30
  }
  ConfigurationValue {
    id: coverPageAlwaysRefresh
    key: "/apps/rutefisk/coverpage/alwaysrefresh"
    defaultValue: true
  }
  ConfigurationValue {
    id: coverPageAutoRefreshInterval
    key: "/apps/rutefisk/coverpage/autorefreshinterval"
    defaultValue: 30
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: contentColumn.height

    Column {
      id: contentColumn
      width: parent.width

      PageHeader {
        title: qsTr("Settings")
      }

      SectionHeader {
        text: qsTr("Realtime information automatic refresh")
      }

      TextSwitch {
        id: autoRefreshToggle
        text: checked ? qsTr("On") : qsTr("Off")
        description: qsTr("Default setting for automatic refresh")
        checked: realTimeAutoRefresh.value

        Binding {
          target: realTimeAutoRefresh
          property: "value"
          value: autoRefreshToggle.checked
        }
      }

      Slider {
        id: autoRefreshIntervalSlider
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 1
        maximumValue: 60
        stepSize: 1.0
        label: qsTr("Refresh interval in seconds")
        valueText: value
        value: realTimeAutoRefreshInterval.value

        Binding {
          target: realTimeAutoRefreshInterval
          property: "value"
          value: autoRefreshIntervalSlider.value
        }
      }

      SectionHeader {
          text: qsTr("Cover page")
      }

      TextSwitch {
        id: alwaysRefreshToggle
        text: checked ? qsTr("Always") : qsTr("Only when visible")
        description: qsTr("Automatically refresh cover page realtime information")
        checked: coverPageAlwaysRefresh.value

        Binding {
          target: coverPageAlwaysRefresh
          property: "value"
          value: alwaysRefreshToggle.checked
        }
      }

      Slider {
        id: coverPageAutoRefreshIntervalSlider
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        minimumValue: 1
        maximumValue: 60
        stepSize: 1.0
        label: qsTr("Refresh interval in seconds")
        valueText: value
        value: coverPageAutoRefreshInterval.value

        Binding {
          target: coverPageAutoRefreshInterval
          property: "value"
          value: coverPageAutoRefreshIntervalSlider.value
        }
      }

    }
  }
}
