
#include "QtTdLibGlobal.h"

#include <QUrl>
#include <QDir>
#include <QStringBuilder>
#include <QImageReader>
#include <QAudioEncoderSettings>
#include <QAudioBuffer>
#include <QAudioDecoder>
#include <QTimer>
#include <QDateTime>
#include <QtMath>

QtTdLibGlobal::QtTdLibGlobal (QObject * parent)
    : QObject { parent }
    , m_chatsList { new QQmlObjectListModel<QtTdLibChat> { this } }
    , m_recordingDuration { 0 }
    , m_selectedPhotosCount { 0 }
    , m_selectedVideosCount { 0 }
    , m_svgIconForMimetype {
{ "image/png", "image" },
{ "image/jpeg", "image" },
{ "image/gif", "image" },
{ "image/svg", "drawing" },
{ "image/svg+xml", "drawing" },
{ "application/vnd.oasis.opendocument.graphics", "drawing" },
{ "audio/mpeg", "sound" },
{ "audio/x-wav", "sound" },
{ "audio/midi", "sound" },
{ "video/mp4", "video" },
{ "text/x-csrc", "code" },
{ "text/x-chdr", "code" },
{ "text/x-c++src", "code" },
{ "text/x-c++hdr", "code" },
{ "text/x-qml", "code" },
{ "text/x-java", "code" },
{ "text/css", "code" },
{ "application/javascript", "code" },
{ "application/xml", "xml" },
{ "application/x-shellscript", "script" },
{ "application/x-perl", "script" },
{ "application/x-object", "binary" },
{ "application/octet-stream", "binary" },
{ "application/x-cd-image", "disk-image" },
{ "application/zip", "archive" },
{ "application/x-xz-compressed-tar", "archive" },
{ "application/x-compressed-tar", "archive" },
{ "application/x-rar", "archive" },
{ "application/x-rpm", "archive" },
{ "application/gzip", "archive" },
{ "application/vnd.debian.binary-package", "archive" },
{ "application/vnd.android.package-archive", "archive" },
{ "application/x-7z-compressed", "archive" },
{ "application/x-bzip-compressed-tar", "archive" },
{ "text/x-makefile", "text" },
{ "text/x-log", "text" },
{ "text/x-theme", "text" },
{ "text/csv", "text" },
{ "text/plain", "text" },
{ "text/vcard", "text" },
{ "text/markdown", "text" },
{ "application/json", "text" },
{ "application/pdf", "pdf" },
{ "application/vnd.oasis.opendocument.text", "document" },
{ "application/vnd.openxmlformats-officedocument.wordprocessingml.document", "document" },
{ "application/msword", "document" },
{ "application/vnd.oasis.opendocument.spreadsheet", "spreadsheet" },
{ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "spreadsheet" },
{ "application/vnd.ms-excel", "spreadsheet" },
{ "application/ms-excel", "spreadsheet" },
{ "application/vnd.oasis.opendocument.presentation", "slideshow" },
{ "application/vnd.openxmlformats-officedocument.presentationml.presentation", "slideshow" },
{ "application/vnd.ms-powerpoint", "slideshow" },
{ "text/html", "webpage" },
{ "application/sql", "database" },
{ "application/x-sqlite3", "database" },
{ "application/x-executable", "executable" },
{ "application/x-ms-dos-executable", "executable" },
          }
    , m_tdLibJsonWrapper { new QtTdLibJsonWrapper { this } }
    , m_audioRecorder    { new QAudioRecorder     { this } }
{
    QAudioEncoderSettings audioEncoderSettings { };
    audioEncoderSettings.setCodec        ("audio/PCM"); // "audio/speex"
    audioEncoderSettings.setEncodingMode (QMultimedia::TwoPassEncoding);
    audioEncoderSettings.setQuality      (QMultimedia::HighQuality);
    audioEncoderSettings.setSampleRate   (22050);
    m_audioRecorder->setEncodingSettings (audioEncoderSettings);
    m_audioRecorder->setContainerFormat  ("wav"); // "ogg"
    connect (m_audioRecorder, &QAudioRecorder::durationChanged, [this] (void) {
        if (m_audioRecorder->status () == QMediaRecorder::RecordingStatus || m_audioRecorder->status () == QMediaRecorder::FinalizingStatus) {
            set_recordingDuration (int (m_audioRecorder->duration ()));
        }
    });
    connect (m_tdLibJsonWrapper, &QtTdLibJsonWrapper::recv, this, &QtTdLibGlobal::onFrame);
    m_tdLibJsonWrapper->start ();
}

QtTdLibGlobal::~QtTdLibGlobal (void) {
    m_tdLibJsonWrapper->send (QJsonObject {
                                  { "@type", "close" }
                              });
    m_tdLibJsonWrapper->quit ();
    m_tdLibJsonWrapper->wait (10000);
}

QObject * QtTdLibGlobal::qmlSingletonFactory (QQmlEngine * qmlEngine, QJSEngine * scriptEngine) {
    Q_UNUSED (qmlEngine)
    Q_UNUSED (scriptEngine)
    return new QtTdLibGlobal { };
}

void QtTdLibGlobal::send (const QJsonObject & json) const {
    QMetaObject::invokeMethod (m_tdLibJsonWrapper, "send", Qt::QueuedConnection, Q_ARG (QJsonObject, json));
}

QJsonObject QtTdLibGlobal::exec (const QJsonObject & json) const {
    return m_tdLibJsonWrapper->exec (json);
}

QString QtTdLibGlobal::formatSize (const int bytes) const {
    static constexpr int KIB  { 1024 };
    static constexpr int MIB  { 1024 * 1024 };
    static constexpr int GIB  { 1024 * 1024 * 1024 };
    static const QString SIZE { "%1 %2" };
    static const QChar   ZERO { '0' };
    if (bytes > GIB) {
        return SIZE.arg ((qreal (bytes) / qreal (GIB)), 0, 'f', 3, ZERO).arg (tr ("GiB"));
    }
    else if (bytes > MIB) {
        return SIZE.arg ((qreal (bytes) / qreal (MIB)), 0, 'f', 2, ZERO).arg (tr ("MiB"));
    }
    else if (bytes > KIB) {
        return SIZE.arg ((qreal (bytes) / qreal (KIB)), 0, 'f', 1, ZERO).arg (tr ("KiB"));
    }
    else {
        return SIZE.arg (bytes).arg (tr ("B"));
    }
}

QString QtTdLibGlobal::formatTime (const int msecs, const bool showHours) const {
    static const QString FULL { "%1:%2:%3" };
    static const QString MINI { "%1:%2" };
    static const QChar   ZERO { '0' };
    int seconds { msecs / 1000 }, hours { 0 }, minutes { 0 };
    if (showHours) {
        hours = (seconds / 3600);
        seconds -= (hours * 3600);
    }
    minutes = (seconds / 60);
    seconds -= (minutes * 60);
    return (showHours
            ? FULL.arg (hours, 2, 10, ZERO).arg (minutes, 2, 10, ZERO).arg (seconds, 2, 10, ZERO)
            : MINI.arg (minutes, 2, 10, ZERO).arg (seconds, 2, 10, ZERO));
}

QVariantList QtTdLibGlobal::parseWaveform (const QString & bytes) const {
    QVariantList ret { };
    ret.reserve (100);
    const QByteArray tmp = QByteArray::fromBase64 (bytes.toLatin1 ());
    if ((tmp.count () * 8 / 5) >= 100) {
        for (int pos = 0; pos < 100; ++pos) {
            int value = 0;
            for (int bit = 0; bit < 5; ++bit) {
                const int offset = (bit + pos * 5);
                if ((tmp.at (offset / 8) >> (offset % 8)) & 0x1) {
                    value |= (0x1 << bit);
                }
                else {
                    value &= ~(0x1 << bit);
                }
            }
            ret.append (value);
        }
    }
    return ret;
}

QString QtTdLibGlobal::urlFromLocalPath (const QString & path) const {
    return QUrl::fromLocalFile (path).toString ();
}

QString QtTdLibGlobal::localPathFromUrl (const QString & url) const {
    return QUrl (url).toLocalFile ();
}

QString QtTdLibGlobal::getSvgIconForMimeType (const QString & type) const {
    return m_svgIconForMimetype.value (type, "file");
}

QtTdLibFile * QtTdLibGlobal::getFileItemById (const qint32 id) const {
    return QtTdLibCollection::allFiles.value (id, Q_NULLPTR);
}

QtTdLibUser * QtTdLibGlobal::getUserItemById (const qint32 id) const {
    return QtTdLibCollection::allUsers.value (id, Q_NULLPTR);
}

QtTdLibChat * QtTdLibGlobal::getChatItemById (const qint64 id) const {
    return QtTdLibCollection::allChats.value (id, Q_NULLPTR);
}

void QtTdLibGlobal::selectPhoto (const QString & path, const int width, const int height) {
    if (!isPhotoSelected (path)) {
        m_selectedPhotosList.append (new SelectionPhoto {
                                         path,
                                         width,
                                         height,
                                     });
        set_selectedPhotosCount (m_selectedPhotosCount +1);
    }
}

void QtTdLibGlobal::deselectPhoto (const QString & path) {
    for (SelectionPhoto * selection : m_selectedPhotosList) {
        if (selection->path == path) {
            m_selectedPhotosList.removeOne (selection);
            set_selectedPhotosCount (m_selectedPhotosCount -1);
            break;
        }
    }
}

bool QtTdLibGlobal::isPhotoSelected (const QString & path) const {
    for (SelectionPhoto * selection : m_selectedPhotosList) {
        if (selection->path == path) {
            return true;
        }
    }
    return false;
}

void QtTdLibGlobal::unselectAllPhotos (void) {
    qDeleteAll (m_selectedPhotosList);
    set_selectedPhotosCount (0);
}

void QtTdLibGlobal::selectVideo (const QString & path, const int width, const int height, const int duration) {
    if (!isVideoSelected (path)) {
        m_selectedVideosList.append (new SelectionVideo {
                                         path,
                                         width,
                                         height,
                                         duration,
                                     });
        set_selectedVideosCount (m_selectedVideosCount +1);
    }
}

void QtTdLibGlobal::deselectVideo (const QString & path) {
    for (SelectionVideo * selection : m_selectedVideosList) {
        if (selection->path == path) {
            m_selectedVideosList.removeOne (selection);
            set_selectedVideosCount (m_selectedVideosCount -1);
            break;
        }
    }
}

bool QtTdLibGlobal::isVideoSelected (const QString & path) const {
    for (SelectionVideo * selection : m_selectedVideosList) {
        if (selection->path == path) {
            return true;
        }
    }
    return false;
}

void QtTdLibGlobal::unselectAllVideos (void) {
    qDeleteAll (m_selectedVideosList);
    set_selectedVideosCount (0);
}

void QtTdLibGlobal::sendMessageText (QtTdLibChat * chatItem, const QString & text) {
    if (chatItem != Q_NULLPTR && !text.isEmpty ()) {
        send (QJsonObject {
                  { "@type", "sendMessage" },
                  { "chat_id" , chatItem->get_id () },
                  { "reply_to_message_id", 0 },
                  { "disable_notification", false },
                  { "from_background", false },
                  { "reply_markup", QJsonValue::Null },
                  { "input_message_content", QJsonObject {
                        { "@type", "inputMessageText" },
                        { "disable_web_page_preview", false },
                        { "clear_draft", false },
                        { "text", exec ({
                              { "@type", "parseTextEntities" },
                              { "text", text },
                              { "parse_mode", {
                                    { "@type", "textParseModeMarkdown" },
                                }
                              }
                          })
                        }
                    }
                  }
              });
    }
}

void QtTdLibGlobal::sendMessagePhoto (QtTdLibChat * chatItem, const bool groupInAlbum) {
    if (chatItem != Q_NULLPTR && !m_selectedPhotosList.isEmpty ()) {
        if (groupInAlbum) {
            QJsonArray contents { };
            for (SelectionPhoto * selection : m_selectedPhotosList) {
                contents.append (QJsonObject {
                                     { "@type", "inputMessagePhoto" },
                                     { "width", selection->width },
                                     { "height", selection->height },
                                     { "photo", QJsonObject {
                                           { "@type", "inputFileLocal" },
                                           { "path", selection->path },
                                       }
                                     }
                                 });
            }
            if (!contents.isEmpty ()) {
                send (QJsonObject {
                          { "@type", "sendMessageAlbum" },
                          { "chat_id", chatItem->get_id () },
                          { "reply_to_message_id", 0  },
                          { "disable_notification", false },
                          { "from_background", false },
                          { "input_message_contents", contents }
                      });
            }
        }
        else {
            for (SelectionPhoto * selection : m_selectedPhotosList) {
                send (QJsonObject {
                          { "@type", "sendMessage" },
                          { "chat_id", chatItem->get_id () },
                          { "reply_to_message_id", 0  },
                          { "disable_notification", false },
                          { "from_background", false },
                          { "input_message_content", QJsonObject {
                                { "@type", "inputMessagePhoto" },
                                { "width", selection->width },
                                { "height", selection->height },
                                { "photo", QJsonObject {
                                      { "@type", "inputFileLocal" },
                                      { "path", selection->path },
                                  }
                                }
                            }
                          }
                      });
            }
        }
    }
}

void QtTdLibGlobal::sendMessageVideo (QtTdLibChat * chatItem, const bool groupInAlbum) {
    if (chatItem != Q_NULLPTR && !m_selectedVideosList.isEmpty ()) {
        if (groupInAlbum) {
            QJsonArray contents { };
            for (SelectionVideo * selection : m_selectedVideosList) {
                contents.append (QJsonObject {
                                     { "@type", "inputMessageVideo" },
                                     { "width", selection->width },
                                     { "height", selection->height },
                                     { "duration", selection->duration },
                                     { "photo", QJsonObject {
                                           { "@type", "inputFileLocal" },
                                           { "path", selection->path },
                                       }
                                     }
                                 });
            }
            if (!contents.isEmpty ()) {
                send (QJsonObject {
                          { "@type", "sendMessageAlbum" },
                          { "chat_id", chatItem->get_id () },
                          { "reply_to_message_id", 0  },
                          { "disable_notification", false },
                          { "from_background", false },
                          { "input_message_contents", contents }
                      });
            }
        }
        else {
            for (SelectionVideo * selection : m_selectedVideosList) {
                send (QJsonObject {
                          { "@type", "sendMessage" },
                          { "chat_id", chatItem->get_id () },
                          { "reply_to_message_id", 0  },
                          { "disable_notification", false },
                          { "from_background", false },
                          { "input_message_content", QJsonObject {
                                { "@type", "inputMessageVideo" },
                                { "width", selection->width },
                                { "height", selection->height },
                                { "duration", selection->duration },
                                { "video", QJsonObject {
                                      { "@type", "inputFileLocal" },
                                      { "path", selection->path },
                                  }
                                }
                            }
                          }
                      });
            }
        }
    }
}

void QtTdLibGlobal::sendMessageVoiceNote (QtTdLibChat * chatItem, const QString & recording) {
    if (chatItem != Q_NULLPTR && QFile::exists (recording)) {
        QByteArray waveform { };
        waveform.reserve (100);
        for (quint8 byte { 0 }; byte < 100; ++byte) {
            waveform.append (qrand () % 0xFF);
        }
        send (QJsonObject {
                  { "@type", "sendMessage" },
                  { "chat_id", chatItem->get_id () },
                  { "reply_to_message_id", 0  },
                  { "disable_notification", false },
                  { "from_background", false },
                  { "input_message_content", QJsonObject {
                        { "@type", "inputMessageVoiceNote" },
                        { "duration", qCeil (m_recordingDuration / 1000.0) },
                        { "waveform", QString::fromLatin1 (waveform.toBase64 ()) },  // TODO
                        { "voice_note", QJsonObject {
                              { "@type", "inputFileLocal" },
                              { "path", recording },
                          }
                        }
                    }
                  }
              });
    }
}

bool QtTdLibGlobal::startRecordingAudio (void) {
    if (m_audioRecorder->status () == QMediaRecorder::LoadedStatus) {
        QDir ().mkpath ("/home/nemo/.telegrame/recordings");
        m_audioRecorder->setOutputLocation (QUrl ("file:///home/nemo/.telegrame/recordings/rec_" % QDateTime::currentDateTimeUtc ().toString ("yyyy-MM-dd_hh-mm-ss-zzz") % ".wav"));
        m_audioRecorder->record ();
        return true;
    }
    else {
        return false;
    }
}

QString QtTdLibGlobal::stopRecordingAudio (void) {
    if (m_audioRecorder->status () == QMediaRecorder::RecordingStatus) {
        m_audioRecorder->stop ();
        return m_audioRecorder->outputLocation ().toLocalFile ();
    }
    else {
        return "";
    }
}

void QtTdLibGlobal::onFrame (const QJsonObject & json) {
    switch (QtTdLibEnums::objectTypeEnumFromJson (json)) {
        case QtTdLibObjectType::UPDATE_AUTHORIZATION_STATE: {
            set_authorizationState_withJSON (json ["authorization_state"], &QtTdLibAuthorizationState::createAbstract);
            if (m_authorizationState) {
                switch (m_authorizationState->get_typeOf ()) {
                    case QtTdLibObjectType::AUTHORIZATION_STATE_WAIT_TDLIB_PARAMETERS: {
                        send (QJsonObject {
                                  { "@type", "setTdlibParameters" },
                                  { "parameters", QJsonObject {
                                        { "api_id", 27687 },
                                        { "api_hash", "dfc01707ab3b6aefe4a7fcfb83ea275c" },
                                        { "use_test_dc", false },
                                        { "use_file_database", true },
                                        { "use_chat_info_database", true },
                                        { "use_message_database", true },
                                        { "use_secret_chats", true },
                                        { "system_language_code", "en" },
                                        { "device_model", "Jolla Sailfish OS" },
                                        { "system_version", "3.x" },
                                        { "application_version", "0.9" },
                                        { "enable_storage_optimizer", true },
                                        { "database_directory", QString (QDir::homePath () % "/.telegrame") },
                                        { "files_directory", QString (QDir::homePath () % "/.telegrame") },
                                        //{ "ignore_file_names", false },
                                    }
                                  }
                              });
                        break;
                    }
                    case QtTdLibObjectType::AUTHORIZATION_STATE_WAIT_ENCRYPTION_KEY: {
                        send (QJsonObject {
                                  { "@type", "setDatabaseEncryptionKey" },
                                  { "new_encryption_key",            "" },
                              });
                        break;
                    }
                    case QtTdLibObjectType::AUTHORIZATION_STATE_READY: {
                        send (QJsonObject {
                                  { "@type",       "getChats" },
                                  { "offset_order", "1000000" },
                                  { "offset_chat_id", 1000000 },
                                  { "limit",          1000000 },
                              });
                        send (QJsonObject {
                                  { "@type", "getInstalledStickerSets" },
                                  { "is_masks",                  false },
                              });
                        send (QJsonObject {
                                  { "@type", "getSavedAnimations" },
                              });
                        break;
                    }
                    default: break;
                }
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_CONNECTION_STATE: {
            set_connectionState_withJSON (json ["state"], &QtTdLibConnectionState::createAbstract);
            break;
        }
        case QtTdLibObjectType::UPDATE_FILE: {
            const QJsonObject fileJson { json ["file"].toObject () };
            const qint32 fileId { QtTdLibId32Helper::fromJsonToCpp (fileJson ["id"]) };
            if (QtTdLibFile * fileItem = { getFileItemById (fileId) }) {
                fileItem->updateFromJson (fileJson);
            }
        }
        case QtTdLibObjectType::UPDATE_USER: {
            const QJsonObject userJson { json ["user"].toObject () };
            const qint32 userId { QtTdLibId32Helper::fromJsonToCpp (userJson ["id"]) };
            if (QtTdLibUser * userItem = { getUserItemById (userId) }) {
                userItem->updateFromJson (userJson);
            }
            else {
                QtTdLibUser::create (userJson, this);
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_USER_STATUS: {
            const QJsonObject statusJson { json ["status"].toObject () };
            const qint32 userId { QtTdLibId32Helper::fromJsonToCpp (json ["user_id"]) };
            if (QtTdLibUser * userItem = { getUserItemById (userId) }) {
                userItem->set_status_withJSON (statusJson, &QtTdLibUserStatus::createAbstract);
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_NEW_CHAT: {
            const QJsonObject chatJson { json ["chat"].toObject () };
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (chatJson ["id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                chatItem->updateFromJson (chatJson);
            }
            else {
                m_chatsList->append (QtTdLibChat::create (chatJson, this));
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_CHAT_READ_INBOX: {
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (json ["chat_id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                chatItem->set_lastReadInboxMessageId_withJSON (json ["last_read_inbox_message_id"]);
                chatItem->set_unreadCount_withJSON (json ["unread_count"]);
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_CHAT_READ_OUTBOX: {
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (json ["chat_id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                chatItem->set_lastReadOutboxMessageId_withJSON (json ["last_read_outbox_message_id"]);
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_NEW_MESSAGE: {
            const QJsonObject messageJson { json ["message"].toObject () };
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["chat_id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                const qint64 messageId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["id"]) };
                if (QtTdLibMessage * messageItem = { chatItem->getMessageItemById (messageId) }) {
                    messageItem->updateFromJson (messageJson);
                }
                else {
                    chatItem->get_messagesModel ()->append (QtTdLibMessage::create (messageJson, chatItem));
                }
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_CHAT_LAST_MESSAGE: {
            const QJsonObject messageJson { json ["last_message"].toObject () };
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["chat_id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                const qint64 messageId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["id"]) };
                if (QtTdLibMessage * messageItem = { chatItem->getMessageItemById (messageId) }) {
                    messageItem->updateFromJson (messageJson);
                }
                else {
                    chatItem->get_messagesModel ()->append (QtTdLibMessage::create (messageJson, chatItem));
                }
            }
            break;
        }
        case QtTdLibObjectType::MESSAGES: {
            const QJsonArray messagesListJson = json ["messages"].toArray ();
            for (const QJsonValue & tmp : messagesListJson) {
                const QJsonObject messageJson { tmp.toObject () };
                const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["chat_id"]) };
                if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                    const qint64 messageId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["id"]) };
                    if (QtTdLibMessage * messageItem = { chatItem->getMessageItemById (messageId) }) {
                        messageItem->updateFromJson (messageJson);
                    }
                    else {
                        chatItem->get_messagesModel ()->prepend (QtTdLibMessage::create (messageJson, chatItem));
                    }
                }
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_DELETE_MESSAGES: {
            if (json ["is_permanent"].toBool ()) {
                const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (json ["chat_id"]) };
                if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                    const QJsonArray messagesListJson = json ["message_ids"].toArray ();
                    for (const QJsonValue & tmp : messagesListJson) {
                        const qint64 messageId { QtTdLibId53Helper::fromJsonToCpp (tmp) };
                        if (QtTdLibMessage * messageItem = { chatItem->getMessageItemById (messageId) }) {
                            qWarning () << "PERMANENTLY DELETING MESSAGE" << messageId << messageItem;
                            chatItem->allMessages.remove (messageId); // FIXME : collection should auto-deref it...
                            chatItem->get_messagesModel ()->remove (messageItem);
                            messageItem->deleteLater ();
                        }
                    }
                }
            }
            break;
        }
        case QtTdLibObjectType::UPDATE_MESSAGE_SEND_SUCCEEDED: {
            const QJsonObject messageJson { json ["message"].toObject () };
            const qint64 chatId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["chat_id"]) };
            if (QtTdLibChat * chatItem = { getChatItemById (chatId) }) {
                const qint64 messageId { QtTdLibId53Helper::fromJsonToCpp (messageJson ["id"]) };
                if (QtTdLibMessage * messageItem = { chatItem->getMessageItemById (messageId) }) {
                    messageItem->updateFromJson (messageJson);
                }
                else {
                    chatItem->get_messagesModel ()->append (QtTdLibMessage::create (messageJson, chatItem));
                }
                const qint64 oldMessageId { QtTdLibId53Helper::fromJsonToCpp (json ["old_message_id"]) };
                if (QtTdLibMessage * oldMessageItem = { chatItem->getMessageItemById (oldMessageId) }) {
                    qWarning () << "DELETING OLD TEMPORARY MESSAGE" << oldMessageId << oldMessageItem;
                    chatItem->allMessages.remove (oldMessageId); // FIXME : collection should auto-deref it...
                    chatItem->get_messagesModel ()->remove (oldMessageItem);
                    oldMessageItem->deleteLater ();
                }
            }
            break;
        }
        default: break;
    }
}
