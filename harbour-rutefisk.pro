# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-rutefisk

CONFIG += sailfishapp

SOURCES += src/harbour-rutefisk.cpp

OTHER_FILES += qml/harbour-rutefisk.qml \
    qml/cover/CoverPage.qml \
    qml/cover/cover.svg \
    qml/pages/MainPage.qml \
    qml/pages/RealTime.qml \
    qml/icons/*.svg \
    qml/scripts/*.js \
    rpm/harbour-rutefisk.changes.in \
    rpm/harbour-rutefisk.spec \
    rpm/harbour-rutefisk.yaml \
    translations/*.ts \
    harbour-rutefisk.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-rutefisk-nb.ts
TRANSLATIONS += translations/harbour-rutefisk-sv.ts

DISTFILES += \  
    qml/pages/RealTimeLine.qml \
    qml/pages/FindFromTo.qml \
    qml/pages/TravelFromTo.qml \
    qml/pages/TravelFromToOptions.qml \
    qml/pages/FindFromToStreet.qml \
    qml/pages/Favorites.qml \
    qml/pages/ShowStops.qml \
    qml/pages/Settings.qml

