import QtQuick 2.1;
import Sailfish.Silica 1.0;
import QtQmlTricks 3.0;
import harbour.Telegrame 1.0;
import "../components";

Page {
    id: page;

    SilicaListView {
        id: flickerContacts;
        anchors.fill: parent;
        model: TD_Global.sortedContactsList;
        section {
            property: "firstName";
            criteria: ViewSection.FirstCharacter;
            delegate: SectionHeader {
                text: section;
            }
        }
        header: Item {
            implicitHeight: headerContacts.height;
            ExtraAnchors.horizontalFill: parent;
        }
        delegate: ListItem {
            id: delegateContact;
            ExtraAnchors.horizontalFill: parent;
            onClicked: {
                pageStack.push (compoPageUserInfo, {
                                    "userItem" : userItem,
                                });
            }

            readonly property TD_User userItem : modelData;

            RowContainer {
                id: layout;
                spacing: Theme.paddingMedium;
                anchors {
                    margins: Theme.paddingMedium;
                    verticalCenter: parent.verticalCenter;
                }
                ExtraAnchors.horizontalFill: parent;

                DelegateDownloadableImage {
                    id: ico;
                    size: Theme.iconSizeMedium;
                    fileItem: (delegateContact.userItem && delegateContact.userItem.profilePhoto
                               ? delegateContact.userItem.profilePhoto.big
                               : null);
                    autoDownload: true;
                    anchors.verticalCenter: parent.verticalCenter;
                }
                LabelFixed {
                    id: lbl;
                    text: (delegateContact.userItem ? delegateContact.userItem.firstName + " " + delegateContact.userItem.lastName : "");
                    anchors.verticalCenter: parent.verticalCenter;
                    Container.horizontalStretch: 1;
                }
            }
        }
    }
    VerticalScrollDecorator {
        flickable: flickerContacts;
    }
    Rectangle {
        id: headerContacts;
        color: Qt.rgba (1.0 - Theme.primaryColor.r, 1.0 - Theme.primaryColor.g, 1.0 - Theme.primaryColor.b, 0.85);
        implicitHeight: (title.height + title.anchors.margins * 2);
        ExtraAnchors.topDock: parent;

        LabelFixed {
            id: title;
            text: qsTr ("All contacts");
            color: Theme.highlightColor;
            font {
                family: Theme.fontFamilyHeading;
                pixelSize: Theme.fontSizeLarge;
            }
            anchors {
                right: parent.right
                margins: Theme.paddingLarge;
                verticalCenter: parent.verticalCenter;
            }
        }
    }
}
