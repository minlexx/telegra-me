import QtQuick 2.6;
import QtMultimedia 5.6;
import QtQmlTricks 3.0;
import Sailfish.Silica 1.0;
import Qt.labs.folderlistmodel 2.1;
import QtDocGallery 5.0;
import QtFeedback 5.0;
import Nemo.Thumbnailer 1.0;
import Nemo.Notifications 1.0;
import Nemo.Configuration 1.0;
import harbour.Telegrame 1.0;
import "cover";
import "pages";
import "components";

ApplicationWindow {
    id: window;
    cover: compoPageCover;
    initialPage: compoPageMain;
    allowedOrientations: Orientation.All;
    onActiveChanged: {
        TD_Global.setUserOnlineState (active);
    }
    Component.onCompleted: {
        TD_Global.setUserOnlineState (true);
    }
    Component.onDestruction: {
        TD_Global.setUserOnlineState (false);
    }

    property string currentRecording : "";
    property string currentDocument  : "";

    property TD_Sticker currentSticker : null;
    property TD_StickerSet currentStickerSet : {
        var ret = null;
        // var ret = TD_Global.stickerSetsList.getFirst (); // asserts if list is empty
        if (TD_Global.stickerSetsList.count > 0 && Helpers.lastUsedStickersetName !== "") {
            for (var idx = 0; idx < TD_Global.stickerSetsList.count; ++idx) {
                var tmp = TD_Global.stickerSetsList.get (idx);
                if (tmp ["name"] === Helpers.lastUsedStickersetName) {
                    ret = tmp;
                    break;
                }
            }
        }
        return ret;
    }

    readonly property bool active      : (Qt.application.state === Qt.ApplicationActive);
    readonly property bool isPortrait  : (window.orientation === Orientation.Portrait  || window.orientation === Orientation.PortraitInverted);
    readonly property bool isLandscape : (window.orientation === Orientation.Landscape || window.orientation === Orientation.LandscapeInverted);

    readonly property ShaderEffectSource maskAvatar : {
        switch (Helpers.avatarShape) {
        case "square":   return null; // NOTE : optimization
        case "rounded":  return maskAvatarRounded;
        case "squircle": return maskAvatarSquircle;
        case "circle":   return maskAvatarCircle;
        }
        return "";
    }

    Connections {
        target: TD_Global;
        onShowChatRequested: {
            if (chatItem) {
                console.log ("DISPLAY REQUESTED", chatItem.id);
                window.activate ();
                while (pageStack.depth > 1) {
                    pageStack.navigateBack (PageStackAction.Immediate);
                }
                pageStack.push (compoPageChat, {
                                    "currentChat" : chatItem,
                                },
                                PageStackAction.Immediate);
            }
        }
    }
    ShaderEffectSource {
        id: maskAvatarCircle;
        hideSource: true;
        sourceItem: Image {
            source: "qrc:///images/mask_circle.svg";
        }
    }
    ShaderEffectSource {
        id: maskAvatarRounded;
        hideSource: true;
        sourceItem: Image {
            source: "qrc:///images/mask_rounded.svg";
        }
    }
    ShaderEffectSource {
        id: maskAvatarSquircle;
        hideSource: true;
        sourceItem: Image {
            source: "qrc:///images/mask_squircle.svg";
        }
    }
    Item {
        rotation: {
            switch (window.orientation) {
            case Orientation.Portrait:          return 0;
            case Orientation.Landscape:         return 90;
            case Orientation.PortraitInverted:  return 180;
            case Orientation.LandscapeInverted: return 270;
            }
            return 0;
        }
        implicitWidth: (rotation % 180 !== 0 ? parent.height : parent.width);
        implicitHeight: (rotation % 180 !== 0 ? parent.width : parent.height);
        anchors.centerIn: parent;

        MouseArea {
            id: footerChat;
            visible: enabled;
            enabled: Helpers.showInputPanel;
            opacity: (enabled ? 1.0 : 0.0);
            implicitHeight: (layoutFooter.height + layoutFooter.anchors.margins * 2);
            ExtraAnchors.bottomDock: parent;
            onPressed: { }
            onReleased: { }

            Rectangle {
                color: Helpers.panelColor;
                anchors.fill: parent;
            }
            ColumnContainer {
                id: layoutFooter;
                spacing: 1;
                ExtraAnchors.bottomDock: parent;

                ColumnContainer {
                    id: pickerPhotoGallery;
                    enabled: !selectorMsgType.visible;
                    opacity: (enabled ? 1.0 : 0.35);
                    visible: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_PHOTO);
                    ExtraAnchors.horizontalFill: parent;

                    RowContainer {
                        spacing: Theme.paddingMedium;
                        anchors.margins: Theme.paddingSmall;
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (implicitHeight + anchors.margins * 2);

                        RectangleButton {
                            icon: "icon-m-clear";
                            size: (Theme.iconSizeMedium * 0.65);
                            enabled: (TD_Global.selectedPhotosCount > 0);
                            implicitWidth: Theme.itemSizeExtraSmall;
                            implicitHeight: Theme.itemSizeExtraSmall;
                            anchors.verticalCenter: parent.verticalCenter;
                            onClicked: {
                                TD_Global.unselectAllPhotos ();
                            }
                        }
                        LabelFixed {
                            text: (TD_Global.selectedPhotosCount > 0
                                   ? (TD_Global.selectedPhotosCount > 1
                                      ? qsTr ("Send %1 images (as an album)").arg (TD_Global.selectedPhotosCount)
                                      : qsTr ("Send 1 image"))
                                   : qsTr ("No image selected"));
                            color: (TD_Global.selectedPhotosCount > 0 ? Theme.highlightColor : Theme.secondaryColor);
                            anchors.verticalCenter: parent.verticalCenter;
                            Container.horizontalStretch: 1;
                        }
                    }
                    SilicaListView {
                        orientation: ListView.Horizontal;
                        model: DocumentGalleryModel {
                            id: galleryModel;
                            rootType: DocumentGallery.Image;
                            properties: ["url", "filePath", "dateTaken", "mimeType", "width", "height"];
                            autoUpdate: true;
                            sortProperties: ["-dateTaken"];
                        }
                        delegate: MouseArea {
                            id: delegatePhoto;
                            implicitWidth: Theme.itemSizeHuge;
                            implicitHeight: Theme.itemSizeHuge;
                            onClicked: {
                                if (selected) {
                                    TD_Global.deselectPhoto (model.filePath);
                                }
                                else {
                                    TD_Global.selectPhoto (model.filePath, model.width, model.height);
                                }
                            }

                            readonly property bool selected : (TD_Global.selectedPhotosCount > 0 && TD_Global.isPhotoSelected (model.filePath));

                            Image {
                                cache: false;
                                source: ("image://nemoThumbnail/" + model.url);
                                fillMode: Image.PreserveAspectCrop;
                                sourceSize: Qt.size (width, height);
                                asynchronous: true;
                                anchors.fill: parent;
                                anchors.margins: 1;

                                Rectangle {
                                    color: "transparent";
                                    visible: delegatePhoto.selected;
                                    border {
                                        width: 3;
                                        color: Theme.highlightColor;
                                    }
                                    anchors.fill: parent;
                                }
                            }
                        }
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (Theme.itemSizeHuge);

                        HorizontalScrollDecorator { flickable: parent; }
                    }
                }
                ColumnContainer {
                    id: pickerVideoGallery;
                    enabled: !selectorMsgType.visible;
                    opacity: (enabled ? 1.0 : 0.35);
                    visible: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_VIDEO);
                    ExtraAnchors.horizontalFill: parent;

                    RowContainer {
                        spacing: Theme.paddingMedium;
                        anchors.margins: Theme.paddingSmall;
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (implicitHeight + anchors.margins * 2);

                        RectangleButton {
                            icon: "icon-m-clear";
                            size: (Theme.iconSizeMedium * 0.65);
                            enabled: (TD_Global.selectedVideosCount > 0);
                            implicitWidth: Theme.itemSizeExtraSmall;
                            implicitHeight: Theme.itemSizeExtraSmall;
                            anchors.verticalCenter: parent.verticalCenter;
                            onClicked: {
                                TD_Global.unselectAllVideos ();
                            }
                        }
                        LabelFixed {
                            text: (TD_Global.selectedVideosCount > 0
                                   ? (TD_Global.selectedVideosCount > 1
                                      ? qsTr ("Send %1 videos (as an album)").arg (TD_Global.selectedVideosCount)
                                      : qsTr ("Send 1 video"))
                                   : qsTr ("No video selected"));
                            color: (TD_Global.selectedVideosCount > 0 ? Theme.highlightColor : Theme.secondaryColor);
                            anchors.verticalCenter: parent.verticalCenter;
                            Container.horizontalStretch: 1;
                        }
                    }
                    SilicaListView {
                        orientation: ListView.Horizontal;
                        model: DocumentGalleryModel {
                            id: galleryModelVideo;
                            rootType: DocumentGallery.Video;
                            properties: ["url", "filePath", "dateTaken", "mimeType", "width", "height", "duration"];
                            autoUpdate: true;
                            sortProperties: ["-dateTaken"];
                        }
                        delegate: MouseArea {
                            id: delegateVideoSelect;
                            implicitWidth: Theme.itemSizeHuge;
                            implicitHeight: Theme.itemSizeHuge;
                            onClicked: {
                                if (selected) {
                                    TD_Global.deselectVideo (model.filePath);
                                }
                                else {
                                    TD_Global.selectVideo (model.filePath, model.width, model.height, model.duration);
                                }
                            }

                            readonly property bool selected : (TD_Global.selectedVideosCount > 0 && TD_Global.isVideoSelected (model.filePath));

                            Rectangle {
                                color: Theme.secondaryColor;
                                anchors.fill: parent;
                                anchors.margins: 1;

                                Thumbnail {
                                    source: model.url;
                                    mimeType: model.mimeType;
                                    fillMode: Thumbnail.PreserveAspectCrop;
                                    sourceSize: Qt.size (width, height);
                                    anchors.fill: parent;
                                }
                                Rectangle {
                                    color: Qt.rgba (1.0 - Theme.primaryColor.r, 1.0 - Theme.primaryColor.g, 1.0 - Theme.primaryColor.b, 0.65);
                                    implicitHeight: (layoutVideoInfo.height + layoutVideoInfo.anchors.margins * 2);
                                    ExtraAnchors.bottomDock: parent;

                                    RowContainer {
                                        id: layoutVideoInfo;
                                        spacing: Theme.paddingMedium;
                                        anchors.margins: Theme.paddingSmall;
                                        ExtraAnchors.bottomDock: parent;

                                        Image {
                                            source: "image://theme/icon-m-video?%1".arg (Theme.primaryColor);
                                            sourceSize: Qt.size (Theme.iconSizeSmall, Theme.iconSizeSmall);
                                            anchors.verticalCenter: parent.verticalCenter;
                                        }
                                        LabelFixed {
                                            text: TD_Global.formatTime (model.duration * 1000, true);
                                            color: Theme.primaryColor;
                                            font.pixelSize: Theme.fontSizeExtraSmall;
                                            anchors.verticalCenter: parent.verticalCenter;
                                        }
                                    }
                                }
                                Rectangle {
                                    color: "transparent";
                                    visible: delegateVideoSelect.selected;
                                    border {
                                        width: 3;
                                        color: Theme.highlightColor;
                                    }
                                    anchors.fill: parent;
                                }
                            }
                        }
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (Theme.itemSizeHuge);

                        HorizontalScrollDecorator { flickable: parent; }
                    }
                }
                ColumnContainer {
                    id: pickerSticker;
                    enabled: !selectorMsgType.visible;
                    opacity: (enabled ? 1.0 : 0.35);
                    visible: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_STICKER);
                    ExtraAnchors.horizontalFill: parent;

                    Item {
                        implicitHeight: pickerTextInput.height;
                        anchors {
                            top: parent.bottom;
                            horizontalCenter: parent.horizontalCenter;
                        }
                        Container.ignored: true;

                        ColumnContainer {
                            anchors.centerIn: parent;

                            LabelFixed {
                                text: (currentStickerSet
                                       ? currentStickerSet.title
                                       : "");
                                color: Theme.secondaryHighlightColor;
                                font.pixelSize: Theme.fontSizeExtraSmall;
                                anchors.horizontalCenter: parent.horizontalCenter;
                            }
                            LabelFixed {
                                text: (currentSticker
                                       ? currentSticker.emoji
                                       : qsTr ("(select a sticker)"));
                                color: (currentSticker ? Theme.highlightColor : Theme.secondaryColor);
                                font.pixelSize: Theme.fontSizeSmall;
                                anchors.horizontalCenter: parent.horizontalCenter;
                            }
                        }
                    }
                    SilicaListView {
                        orientation: ListView.Horizontal;
                        model: (currentStickerSet ? currentStickerSet.stickers : 0);
                        delegate: MouseArea {
                            id: delegateSelectorSticker;
                            implicitWidth: Theme.itemSizeLarge;
                            implicitHeight: Theme.itemSizeLarge;
                            onClicked: {
                                currentSticker = stickerItem;
                            }

                            readonly property TD_Sticker stickerItem : modelData;

                            HelperFileState {
                                id: helperSelectorStickerFile;
                                fileItem: (delegateSelectorSticker.stickerItem ? delegateSelectorSticker.stickerItem.sticker : null);
                                autoDownload: true;
                            }
                            Image {
                                cache: true;
                                source: helperSelectorStickerFile.url;
                                fillMode: Image.PreserveAspectFit;
                                sourceSize: Qt.size (Theme.itemSizeLarge * 0.85, Theme.itemSizeLarge * 0.85);
                                asynchronous: true;
                                verticalAlignment: Image.AlignVCenter;
                                horizontalAlignment: Image.AlignHCenter;
                                anchors.centerIn: parent;
                            }
                            ProgressCircle {
                                value: helperSelectorStickerFile.progress;
                                visible: helperSelectorStickerFile.downloading;
                                implicitWidth: BusyIndicatorSize.Medium;
                                implicitHeight: BusyIndicatorSize.Medium;
                                anchors.centerIn: parent;
                            }
                            Rectangle {
                                color: "transparent";
                                visible: (delegateSelectorSticker.stickerItem === currentSticker);
                                border {
                                    width: 3;
                                    color: Theme.highlightColor;
                                }
                                anchors.fill: parent;
                            }
                        }
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (Theme.itemSizeLarge);

                        HorizontalScrollDecorator { flickable: parent; }
                    }
                    SilicaListView {
                        model: TD_Global.stickerSetsList;
                        spacing: 1;
                        orientation: ListView.Horizontal;
                        delegate: MouseArea {
                            id: delegateSelectorStickerSet;
                            implicitWidth: height;
                            ExtraAnchors.verticalFill: parent;
                            onClicked: {
                                if (currentStickerSet !== stickerSetItem) {
                                    currentSticker = null;
                                    currentStickerSet = stickerSetItem;
                                    Helpers.lastUsedStickersetName = currentStickerSet.name;
                                }
                            }

                            readonly property TD_StickerSet stickerSetItem : modelData;
                            readonly property TD_Sticker    coverItem      : (stickerSetItem && stickerSetItem.covers.count >= 1 ? stickerSetItem.covers.getFirst () : null);

                            readonly property bool active : (currentStickerSet === stickerSetItem);

                            HelperFileState {
                                id: helperSelectorStickerSetFile;
                                fileItem: (delegateSelectorStickerSet.coverItem ? delegateSelectorStickerSet.coverItem.sticker : null);
                                autoDownload: true;
                            }
                            Rectangle {
                                color: Theme.rgba ((delegateSelectorStickerSet.active || pressed ? Theme.highlightColor : Theme.primaryColor), (delegateSelectorStickerSet.active ? 0.35 : 0.15));
                                anchors.fill: parent;
                            }
                            Image {
                                cache: true;
                                source: helperSelectorStickerSetFile.url;
                                fillMode: Image.PreserveAspectFit;
                                sourceSize: Qt.size (Theme.iconSizeMedium * 0.85, Theme.iconSizeMedium * 0.85);
                                asynchronous: true;
                                verticalAlignment: Image.AlignVCenter;
                                horizontalAlignment: Image.AlignHCenter;
                                anchors.centerIn: parent;
                            }
                            ProgressCircle {
                                value: helperSelectorStickerSetFile.progress;
                                visible: helperSelectorStickerSetFile.downloading;
                                implicitWidth: BusyIndicatorSize.Small;
                                implicitHeight: BusyIndicatorSize.Small;
                                anchors.centerIn: parent;
                            }
                        }
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (Theme.iconSizeMedium * 1.15);
                    }
                }
                ColumnContainer {
                    id: pickerDocumentBrowser;
                    enabled: !selectorMsgType.visible;
                    opacity: (enabled ? 1.0 : 0.35);
                    visible: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_DOCUMENT);
                    ExtraAnchors.horizontalFill: parent;

                    RowContainer {
                        spacing: Theme.paddingMedium;
                        anchors.margins: Theme.paddingSmall;
                        Container.forcedHeight: Math.ceil (implicitHeight + anchors.margins * 2);
                        ExtraAnchors.horizontalFill: parent;

                        RectangleButton {
                            icon: "icon-m-back";
                            size: (Theme.iconSizeMedium * 0.65);
                            enabled: (modelDocuments.folder.toString () !== modelDocuments.limitedTo);
                            implicitWidth: Theme.itemSizeExtraSmall;
                            implicitHeight: Theme.itemSizeExtraSmall;
                            anchors.verticalCenter: parent.verticalCenter;
                            onClicked: {
                                modelDocuments.folder = modelDocuments.parentFolder;
                            }
                        }
                        LabelFixed {
                            text: TD_Global.localPathFromUrl (modelDocuments.folder);
                            elide: Text.ElideLeft;
                            color: Theme.highlightColor;
                            font.pixelSize: Theme.fontSizeSmall;
                            anchors.verticalCenter: parent.verticalCenter;
                            Container.horizontalStretch: 1;
                        }
                    }
                    SilicaListView {
                        clip: true;
                        spacing: 1;
                        orientation: ListView.Vertical;
                        model: FolderListModel {
                            id: modelDocuments;
                            folder: pathHome;
                            rootFolder: limitedTo;
                            showDirs: true;
                            showDirsFirst: true;
                            showDotAndDotDot: false;
                            showFiles: true;
                            showHidden: false;
                            sortReversed: false;
                            sortField: FolderListModel.Name;
                            onLimitedToChanged: {
                                if (folder.toString ().indexOf (limitedTo) !== 0) {
                                    folder = pathHome;
                                }
                            }

                            readonly property string pathRoot  : "file:///";
                            readonly property string pathHome  : "file:///home/nemo";
                            readonly property string limitedTo : (Helpers.limitFilePickerToHome ? pathHome : pathRoot);
                        }
                        delegate: MouseArea {
                            id: delegateSelectorDocument;
                            implicitHeight: (layoutDocument.height + Theme.paddingSmall * 2);
                            ExtraAnchors.horizontalFill: parent;
                            onClicked: {
                                if (model.fileIsDir) {
                                    modelDocuments.folder = model.fileURL;
                                }
                                else {
                                    currentDocument = model.filePath;
                                }
                            }

                            Rectangle {
                                color: Theme.rgba (Theme.highlightColor, (currentDocument === model.filePath ? 0.35 : 0.15));
                                visible: (currentDocument === model.filePath || parent.pressed);
                                anchors.fill: parent;
                            }
                            RowContainer {
                                id: layoutDocument;
                                spacing: Theme.paddingMedium;
                                anchors {
                                    margins: Theme.paddingMedium;
                                    verticalCenter: parent.verticalCenter;
                                }
                                ExtraAnchors.horizontalFill: parent;

                                Image {
                                    source: "qrc:///symbols/filetypes/%1.svg".arg (model.fileIsDir ? "folder-closed" : TD_Global.getSvgIconForMimeType (mimeType));
                                    sourceSize: Qt.size (Theme.iconSizeMedium * 0.85, Theme.iconSizeMedium * 0.85);
                                    anchors.verticalCenter: parent.verticalCenter;

                                    readonly property string mimeType : TD_Global.getMimeTypeForPath (model.filePath);
                                }
                                ColumnContainer {
                                    Container.horizontalStretch: 1;

                                    LabelFixed {
                                        text: model.fileName;
                                        elide: Text.ElideMiddle;
                                        ExtraAnchors.horizontalFill: parent;
                                    }
                                    LabelFixed {
                                        text: TD_Global.formatSize (model.fileSize);
                                        color: Theme.secondaryColor;
                                        visible: !model.fileIsDir;
                                        font.pixelSize: Theme.fontSizeExtraSmall;
                                        ExtraAnchors.horizontalFill: parent;
                                    }
                                }
                            }
                        }
                        ExtraAnchors.horizontalFill: parent;
                        Container.forcedHeight: Math.ceil (Theme.itemSizeLarge * (isPortrait ? 3.85 : 2.35));
                    }
                }
                RowContainer {
                    id: pickerRecorder;
                    enabled: !selectorMsgType.visible;
                    opacity: (enabled ? 1.0 : 0.35);
                    visible: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_VOICE_NOTE);
                    spacing: Theme.paddingMedium;
                    anchors.margins: Theme.paddingSmall;
                    Container.forcedHeight: Math.ceil (implicitHeight + anchors.margins * 2);
                    ExtraAnchors.horizontalFill: parent;

                    Item {
                        implicitHeight: pickerTextInput.height;
                        anchors {
                            top: parent.bottom;
                            horizontalCenter: parent.horizontalCenter;
                        }
                        Container.ignored: true;

                        RowContainer {
                            spacing: Theme.paddingSmall;
                            anchors.centerIn: parent;

                            RectangleButton {
                                id: btnRecord;
                                icon: "icon-m-call-recording-on";
                                enabled: !btnReplay.active;
                                size: (Theme.iconSizeMedium * 0.65);
                                implicitWidth: Theme.itemSizeExtraSmall;
                                implicitHeight: Theme.itemSizeExtraSmall;
                                anchors.verticalCenter: parent.verticalCenter;
                                onPressed: {
                                    active = TD_Global.startRecordingAudio ();
                                    if (active) {
                                        console.log ("RECORDING STARTED", active);
                                        currentRecording = "";
                                    }
                                }
                                onReleased: {
                                    if (active) {
                                        active = false;
                                        currentRecording = TD_Global.stopRecordingAudio ();
                                        console.log ("RECORDING STOPPED", currentRecording);
                                    }
                                }
                            }
                            RectangleButton {
                                id: btnReplay;
                                icon: "icon-m-play";
                                active: (playerRecording.playbackState === MediaPlayer.PlayingState);
                                enabled: (currentRecording !== "");
                                size: (Theme.iconSizeMedium * 0.65);
                                implicitWidth: Theme.itemSizeExtraSmall;
                                implicitHeight: Theme.itemSizeExtraSmall;
                                anchors.verticalCenter: parent.verticalCenter;
                                onClicked: {
                                    if (playerRecording.playbackState !== MediaPlayer.PlayingState) {
                                        playerRecording.source = TD_Global.urlFromLocalPath (currentRecording);
                                        playerRecording.seek (0);
                                        playerRecording.play ();
                                    }
                                    else {
                                        playerRecording.stop ();
                                        playerRecording.source = "";
                                    }
                                }

                                MediaPlayer {
                                    id: playerRecording;
                                    autoLoad: true;
                                    autoPlay: true;
                                    onPlaybackStateChanged: {
                                        if (playbackState === MediaPlayer.StoppedState) {
                                            source = "";
                                        }
                                    }
                                }
                            }
                            RectangleButton {
                                id: btnReset;
                                icon: "icon-m-delete";
                                enabled: (currentRecording !== "" && !btnRecord.active && !btnReplay.active);
                                size: (Theme.iconSizeMedium * 0.65);
                                implicitWidth: Theme.itemSizeExtraSmall;
                                implicitHeight: Theme.itemSizeExtraSmall;
                                anchors.verticalCenter: parent.verticalCenter;
                                onClicked: {
                                    TD_Global.removeRecording (currentRecording);
                                    currentRecording = "";
                                }
                            }
                        }
                    }
                    Item {
                        Container.horizontalStretch: 1;
                    }
                    LabelFixed {
                        text: (btnRecord.active
                               ? qsTr ("Recording (%1)").arg (TD_Global.formatTime (TD_Global.recordingDuration, false))
                               : (currentRecording !== ""
                                  ? ((playerRecording.playbackState === MediaPlayer.PlayingState)
                                     ? qsTr ("Replaying (%1/%2)").arg (TD_Global.formatTime (playerRecording.position, false)).arg (TD_Global.formatTime (playerRecording.duration, false))
                                     : qsTr ("Send recording (%1)").arg (TD_Global.formatTime (TD_Global.recordingDuration, false)))
                                  : qsTr ("Idle")));
                        color: ((btnRecord.active || btnReplay.active)
                                ? Theme.highlightColor
                                : (currentRecording !== ""
                                   ? Theme.primaryColor
                                   : Theme.secondaryColor));
                        anchors.verticalCenter: parent.verticalCenter;
                    }
                    Item {
                        Container.horizontalStretch: 1;
                    }
                }
                RowContainer {
                    id: pickerTextInput;
                    ExtraAnchors.horizontalFill: parent;

                    RectangleButton {
                        active: selectorMsgType.visible;
                        rounded: false;
                        icon: {
                            switch (Helpers.currentMsgType) {
                            case TD_ObjectType.MESSAGE_TEXT:       return "icon-m-text-input";
                            case TD_ObjectType.MESSAGE_PHOTO:      return "icon-m-camera";
                            case TD_ObjectType.MESSAGE_VIDEO:      return "icon-m-video";
                            case TD_ObjectType.MESSAGE_AUDIO:      return "icon-m-music";
                            case TD_ObjectType.MESSAGE_STICKER:    return "icon-m-other";
                            case TD_ObjectType.MESSAGE_ANIMATION:  return "icon-m-favorite";
                            case TD_ObjectType.MESSAGE_VOICE_NOTE: return "icon-m-mic";
                            case TD_ObjectType.MESSAGE_VIDEO_NOTE: return "icon-m-play";
                            case TD_ObjectType.MESSAGE_DOCUMENT:   return "icon-m-attach";
                            }
                        }
                        anchors.bottom: parent.bottom;
                        onClicked: {
                            selectorMsgType.visible = !selectorMsgType.visible;
                        }
                    }
                    Item {
                        opacity: (enabled ? 1.0 : 0.0);
                        enabled: (Helpers.showInputPanel &&
                                  !selectorMsgType.visible &&
                                  (Helpers.currentMsgType === TD_ObjectType.MESSAGE_TEXT  ||
                                   Helpers.currentMsgType === TD_ObjectType.MESSAGE_PHOTO ||
                                   Helpers.currentMsgType === TD_ObjectType.MESSAGE_VIDEO ||
                                   Helpers.currentMsgType === TD_ObjectType.MESSAGE_DOCUMENT));
                        implicitHeight: Math.min (btnSendMsg.textBox.implicitHeight, Theme.itemSizeLarge * 2);
                        anchors.bottom: parent.bottom;
                        anchors.margins: Theme.paddingSmall;
                        Container.horizontalStretch: 1;
                        onEnabledChanged: {
                            if (!enabled) {
                                inputMsg.text = "";
                                inputMsgSingle.text = "";
                                btnSendMsg.textBox.focus = false;
                            }
                        }

                        Timer {
                            id: restoreFocusTimer;
                            repeat: false;
                            running: false;
                            interval: 50;
                            onTriggered: {
                                btnSendMsg.textBox.forceActiveFocus ();
                            }
                        }
                        TextField {
                            id: inputMsgSingle;
                            visible: Helpers.sendTextMsgOnEnterKey;
                            labelVisible: false;
                            placeholderText: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_TEXT
                                              ? qsTr ("Text message")
                                              : qsTr ("Caption"));
                            anchors.fill: parent;
                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    selectorMsgType.visible = false;
                                }
                            }
                            Keys.onReturnPressed: {
                                btnSendMsg.execute ();
                            }
                        }
                        TextArea {
                            id: inputMsg;
                            visible: !Helpers.sendTextMsgOnEnterKey;
                            labelVisible: false;
                            placeholderText: (Helpers.currentMsgType === TD_ObjectType.MESSAGE_TEXT
                                              ? qsTr ("Text message")
                                              : qsTr ("Caption"));
                            autoScrollEnabled: true;
                            anchors.fill: parent;
                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    selectorMsgType.visible = false;
                                }
                            }
                        }
                    }
                    RectangleButton {
                        id: btnSendMsg;
                        icon: "icon-m-enter";
                        size: (Theme.iconSizeMedium * 0.65);
                        enabled: {
                            switch (Helpers.currentMsgType) {
                            case TD_ObjectType.MESSAGE_TEXT:       return (textBox.text.trim () !== "");
                            case TD_ObjectType.MESSAGE_PHOTO:      return (TD_Global.selectedPhotosCount > 0);
                            case TD_ObjectType.MESSAGE_VIDEO:      return (TD_Global.selectedVideosCount > 0);
                            case TD_ObjectType.MESSAGE_VOICE_NOTE: return (currentRecording !== "" && !btnRecord.active && !btnReplay.active);
                            case TD_ObjectType.MESSAGE_STICKER:    return (currentSticker !== null);
                            case TD_ObjectType.MESSAGE_DOCUMENT:   return (currentDocument !== "");
                            }
                            return false;
                        }
                        implicitWidth: Theme.itemSizeExtraSmall;
                        implicitHeight: Theme.itemSizeExtraSmall;
                        anchors.bottom: parent.bottom;
                        onClicked: {
                            execute ();
                        }

                        readonly property Item textBox : (Helpers.sendTextMsgOnEnterKey ? inputMsgSingle : inputMsg);

                        function execute () {
                            if (enabled) {
                                /// PREPARE
                                var restore = (textBox.activeFocus && Helpers.keepKeyboardOpenAfterMsgSend);
                                textBox.focus = false;
                                var tmp = textBox.text.trim ();
                                /// SEND
                                switch (Helpers.currentMsgType) {
                                case TD_ObjectType.MESSAGE_TEXT:
                                    TD_Global.sendMessageText (TD_Global.currentChat, tmp);
                                    break;
                                case TD_ObjectType.MESSAGE_PHOTO:
                                    TD_Global.sendMessagePhoto (TD_Global.currentChat, (TD_Global.selectedPhotosCount > 0), tmp);
                                    break;
                                case TD_ObjectType.MESSAGE_VIDEO:
                                    TD_Global.sendMessageVideo (TD_Global.currentChat, (TD_Global.selectedVideosCount > 0), tmp);
                                    break;
                                case TD_ObjectType.MESSAGE_DOCUMENT:
                                    TD_Global.sendMessageDocument (TD_Global.currentChat, currentDocument, tmp);
                                    break;
                                case TD_ObjectType.MESSAGE_VOICE_NOTE:
                                    TD_Global.sendMessageVoiceNote (TD_Global.currentChat, currentRecording);
                                    break;
                                case TD_ObjectType.MESSAGE_STICKER:
                                    TD_Global.sendMessageSticker (TD_Global.currentChat, currentSticker);
                                    break;
                                }
                                /// RESET
                                TD_Global.unselectAllPhotos ();
                                TD_Global.unselectAllVideos ();
                                currentDocument = "";
                                currentRecording = "";
                                currentSticker = null;
                                textBox.text = "";
                                buzz.play ();
                                if (restore) {
                                    restoreFocusTimer.start ();
                                }
                            }
                        }

                        ThemeEffect {
                            id: buzz;
                            effect: ThemeEffect.Press;
                        }
                    }
                }
                GridContainer {
                    id: selectorMsgType;
                    cols: capacity;
                    visible: false;
                    capacity: repeaterModes.count;
                    horizontalSpacing: 1;
                    ExtraAnchors.horizontalFill: parent;
                    Container.forcedHeight: Math.ceil (Theme.itemSizeSmall * 0.85);

                    Repeater {
                        id: repeaterModes;
                        model: [
                            TD_ObjectType.MESSAGE_TEXT,
                            TD_ObjectType.MESSAGE_PHOTO,
                            TD_ObjectType.MESSAGE_VIDEO,
                            //TD_ObjectType.MESSAGE_AUDIO, // TODO : nice picker
                            TD_ObjectType.MESSAGE_STICKER,
                            //TD_ObjectType.MESSAGE_ANIMATION, // TODO : non laggy picker
                            TD_ObjectType.MESSAGE_VOICE_NOTE,
                            //TD_ObjectType.MESSAGE_VIDEO_NOTE, // TODO : video recorder
                            TD_ObjectType.MESSAGE_DOCUMENT,
                        ];
                        delegate: RectangleButton {
                            size: Theme.iconSizeMedium;
                            active: (Helpers.currentMsgType === modelData);
                            rounded: false;
                            icon: {
                                switch (modelData) {
                                case TD_ObjectType.MESSAGE_TEXT:       return "icon-m-text-input";
                                case TD_ObjectType.MESSAGE_PHOTO:      return "icon-m-camera";
                                case TD_ObjectType.MESSAGE_VIDEO:      return "icon-m-video";
                                case TD_ObjectType.MESSAGE_AUDIO:      return "icon-m-music";
                                case TD_ObjectType.MESSAGE_STICKER:    return "icon-m-other";
                                case TD_ObjectType.MESSAGE_ANIMATION:  return "icon-m-favorite";
                                case TD_ObjectType.MESSAGE_VOICE_NOTE: return "icon-m-mic";
                                case TD_ObjectType.MESSAGE_VIDEO_NOTE: return "icon-m-play";
                                case TD_ObjectType.MESSAGE_DOCUMENT:   return "icon-m-attach";
                                }
                            }
                            onClicked: {
                                if (Helpers.currentMsgType !== modelData) {
                                    Helpers.currentMsgType = modelData;
                                    btnSendMsg.textBox.focus = false;
                                }
                                selectorMsgType.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }
    Component { id: compoPageCover; CoverPage { } }
    Component { id: compoPageMain; PageMain { } }
    Component { id: compoPageContacts; PageContacts { } }
    Component { id: compoPageChat; PageChat { } }
    Component { id: compoPageSettings; PageSettings { } }
    Component { id: compoPageAbout; PageAbout { } }
    Component { id: compoPageUserInfo; PageUserInfo { } }
    Component { id: compoPageChatInfoPrivate; PageChatInfoPrivate { } }
    Component { id: compoPageChatInfoBasicGroup; PageChatInfoBasicGroup { } }
    Component { id: compoPageChatInfoSupergroup; PageChatInfoSupergroup { } }
    Component { id: compoMsgText; DelegateMessageText { } }
    Component { id: compoMsgPhoto; DelegateMessagePhoto { } }
    Component { id: compoMsgDocument; DelegateMessageDocument { } }
    Component { id: compoMsgSticker; DelegateMessageSticker { } }
    Component { id: compoMsgVideo; DelegateMessageVideo { } }
    Component { id: compoMsgAudio; DelegateMessageAudio { } }
    Component { id: compoMsgAnimation; DelegateMessageAnimation { } }
    Component { id: compoMsgVoiceNote; DelegateMessageVoiceNote { } }
    Component { id: compoMsgChatJoinByLink; DelegateMessageChatJoinByLink { } }
    Component { id: compoMsgChatAddMembers; DelegateMessageChatAddMembers { } }
    Component { id: compoMsgChatDeleteMember; DelegateMessageChatDeleteMember { } }
    Component { id: compoMsgChatChangeTitle; DelegateMessageChatChangeTitle { } }
    Component { id: compoMsgChatUpgradeFrom; DelegateMessageChatUpgradeFrom { } }
    Component { id: compoMsgChatUpgradeTo; DelegateMessageChatUpgradeTo { } }
    Component { id: compoMsgChatContactRegistered; DelegateMessageChatContactRegistered { } }
    Component { id: compoMsgPinMessage; DelegateMessagePinMessage { } }
    Component { id: compoMsgBasicGroupChatCreate; DelegateMessageBasicGroupChatCreate { } }
    Component { id: compoMsgSupergroupChatCreate; DelegateMessageSupergroupChatCreate { } }
    Component { id: compoMsgCall; DelegateMessageCall { } }
    Component { id: compoMsgChatChangePhoto; DelegateMessageChatChangePhoto { } }
    Component { id: compoMsgUnsupported; DelegateMessageUnsupported { } }
}
