
include ($$PWD/libQtQmlTricks/libQtQmlTricks-3.0.pri)

TARGET = harbour-telegrame

TEMPLATE = app

CONFIG += c++11

QT += core network gui qml quick multimedia dbus

MOC_DIR     = _moc
OBJECTS_DIR = _obj
RCC_DIR     = _rcc

CONFIG += link_pkgconfig

PKGCONFIG += sailfishapp
PKGCONFIG += nemonotifications-qt5
PKGCONFIG += mlite5
PKGCONFIG += libssl libcrypto
PKGCONFIG += zlib

INCLUDEPATH += \
    /usr/include \
    /usr/include/sailfishapp \
    $$PWD/src

SOURCES += \
    $$PWD/src/harbour-telegrame.cpp \
    $$PWD/src/QtTdLibJsonWrapper.cpp \
    $$PWD/src/QtTdLibEnums.cpp \
    $$PWD/src/QtTdLibCommon.cpp \
    $$PWD/src/QtTdLibConnection.cpp \
    $$PWD/src/QtTdLibGlobal.cpp \
    $$PWD/src/QtTdLibAuth.cpp \
    $$PWD/src/QtTdLibChat.cpp \
    $$PWD/src/QtTdLibContent.cpp \
    $$PWD/src/QtTdLibFile.cpp \
    $$PWD/src/QtTdLibMessage.cpp \
    $$PWD/src/QtTdLibUser.cpp \
    $$PWD/src/TextFormatter.cpp

HEADERS += \
    $$PWD/src/QtTdLibJsonWrapper.h \
    $$PWD/src/QtTdLibEnums.h \
    $$PWD/src/QtTdLibCommon.h \
    $$PWD/src/QtTdLibConnection.h \
    $$PWD/src/QtTdLibGlobal.h \
    $$PWD/src/QtTdLibAuth.h \
    $$PWD/src/QtTdLibChat.h \
    $$PWD/src/QtTdLibContent.h \
    $$PWD/src/QtTdLibFile.h \
    $$PWD/src/QtTdLibMessage.h \
    $$PWD/src/QtTdLibUser.h \
    $$PWD/src/TextFormatter.h

RESOURCES += \
    $$PWD/qml.qrc \
    $$PWD/flags.qrc \
    $$PWD/icons.qrc \
    $$PWD/symbols.qrc \
    $$PWD/images.qrc

OTHER_FILES += \
    $$PWD/rpm/$${TARGET}.yaml

DISTFILES += \
    $$PWD/$${TARGET}.desktop \
    $$PWD/icons/86x86/$${TARGET}.png \
    $$PWD/icons/108x108/$${TARGET}.png \
    $$PWD/icons/128x128/$${TARGET}.png \
    $$PWD/icons/172x172/$${TARGET}.png \
    $$PWD/dist/x-telegrame.im.conf \
    $$PWD/dist/x-telegrame.im.fg.conf \
    $$PWD/dist/telegrame_im.ini \
    $$PWD/dist/telegrame_im_exists.ini \
    $$PWD/dist/telegrame_im_fg.ini

LIBS += -ltdjson

target.files  = $${TARGET}
target.path   = /usr/bin

desktop.files = $$PWD/$${TARGET}.desktop
desktop.path  = /usr/share/applications

icon86.files  = $$PWD/icons/86x86/$${TARGET}.png
icon86.path   = /usr/share/icons/hicolor/86x86/apps

icon108.files = $$PWD/icons/108x108/$${TARGET}.png
icon108.path  = /usr/share/icons/hicolor/108x108/apps

icon128.files = $$PWD/icons/128x128/$${TARGET}.png
icon128.path  = /usr/share/icons/hicolor/128x128/apps

icon256.files = $$PWD/icons/256x256/$${TARGET}.png
icon256.path  = /usr/share/icons/hicolor/256x256/apps

notificationcategories.files = $$PWD/dist/x-telegrame.im.conf $$PWD/dist/x-telegrame.im.fg.conf
notificationcategories.path  = /usr/share/lipstick/notificationcategories

events.files = $$PWD/dist/telegrame_im.ini $$PWD/dist/telegrame_im_exists.ini $$PWD/dist/telegrame_im_fg.ini
events.path  = /usr/share/ngfd/events.d

INSTALLS += target desktop icon86 icon108 icon128 icon256 notificationcategories events
