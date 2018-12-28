
#include "QtTdLibJsonWrapper.h"
#include "QtTdLibEnums.h"

#include <QStringBuilder>
#include <QJsonDocument>
#include <QDebug>

#include <td/telegram/td_json_client.h>
#include <td/telegram/td_log.h>

QtTdLibJsonWrapper::QtTdLibJsonWrapper (QObject * parent)
    : QThread              { parent }
    , m_tdJsonClientHandle { td_json_client_create () }
{
#ifdef QT_DEBUG
    td_set_log_verbosity_level (5); // verbose logging in debug builds
#else
    td_set_log_verbosity_level (1);
#endif
}

QtTdLibJsonWrapper::~QtTdLibJsonWrapper (void) {
    td_json_client_destroy (m_tdJsonClientHandle);
}

void QtTdLibJsonWrapper::run (void) {
    forever {
        const QByteArray tmp { QByteArray (td_json_client_receive (m_tdJsonClientHandle, 1)) };
        if (!tmp.isEmpty ()) {
            const QJsonObject json { QJsonDocument::fromJson (tmp).object () };
            if (!json.isEmpty ()) {
                qWarning () << "RECV" << json;
                emit recv (json);
                if (QtTdLibEnums::objectTypeEnumFromJson (json) == QtTdLibObjectType::UPDATE_AUTHORIZATION_STATE) {
                    if (QtTdLibEnums::objectTypeEnumFromJson (json ["authorization_state"].toObject ()) == QtTdLibObjectType::AUTHORIZATION_STATE_CLOSED) {
                        break;
                    }
                }
            }
        }
    }
}

QJsonObject QtTdLibJsonWrapper::exec (const QJsonObject & json) {
    qWarning () << "EXEC" << json;
    const QByteArray  tmp { (QJsonDocument (json).toJson (QJsonDocument::Compact) % '\0') };
    const QByteArray  str { QByteArray (td_json_client_execute (m_tdJsonClientHandle, tmp.constData ())) };
    const QJsonObject ret { QJsonDocument::fromJson (str).object () };
    qWarning () << "RESULT" << ret;
    return ret;
}

void QtTdLibJsonWrapper::send (const QJsonObject & json) {
    qWarning () << "SEND" << json;
    const QByteArray tmp { (QJsonDocument (json).toJson (QJsonDocument::Compact) % '\0') };
    td_json_client_send (m_tdJsonClientHandle, tmp.constData ());
}
