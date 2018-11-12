
#include "QtTdLibUser.h"

QtTdLibProfilePhoto::QtTdLibProfilePhoto (const QString & id, QObject * parent)
    : QtTdLibAbstractStrIdObject { QtTdLibObjectType::PROFILE_PHOTO, id, parent }
{ }

void QtTdLibProfilePhoto::updateFromJson (const QJsonObject & json) {
    set_big_withJSON   (json ["big"],   &QtTdLibAbstractInt32IdObject::create<QtTdLibFile>);
    set_small_withJSON (json ["small"], &QtTdLibAbstractInt32IdObject::create<QtTdLibFile>);
}

QtTdLibLinkState::QtTdLibLinkState (const QtTdLibObjectType::Type typeOf, QObject * parent)
    : QtTdLibAbstractObject { typeOf, parent }
{ }

QtTdLibLinkState * QtTdLibLinkState::create (const QJsonObject & json, QObject * parent) {
    switch (QtTdLibEnums::objectTypeEnumFromJson (json)) {
        case QtTdLibObjectType::LINK_STATE_IS_CONTACT:         return new QtTdLibLinkStateIsContact { parent };
        case QtTdLibObjectType::LINK_STATE_KNOWS_PHONE_NUMBER: return new QtTdLibLinkStateKnowsPhoneNumber { parent };
        case QtTdLibObjectType::LINK_STATE_NONE:               return new QtTdLibLinkStateNone { parent };
        default: return Q_NULLPTR;
    }
}

QtTdLibLinkStateNone::QtTdLibLinkStateNone (QObject * parent)
    : QtTdLibLinkState { QtTdLibObjectType::LINK_STATE_NONE, parent }
{ }

QtTdLibLinkStateKnowsPhoneNumber::QtTdLibLinkStateKnowsPhoneNumber (QObject * parent)
    : QtTdLibLinkState { QtTdLibObjectType::LINK_STATE_KNOWS_PHONE_NUMBER, parent }
{ }

QtTdLibLinkStateIsContact::QtTdLibLinkStateIsContact (QObject * parent)
    : QtTdLibLinkState { QtTdLibObjectType::LINK_STATE_IS_CONTACT, parent }
{ }

QtTdLibUser::QtTdLibUser (const qint32 id, QObject * parent)
    : QtTdLibAbstractInt32IdObject { QtTdLibObjectType::USER, id, parent }
{
    QtTdLibCollection::allUsers.insert (id, this);
}

void QtTdLibUser::updateFromJson (const QJsonObject & json) {
    set_phoneNumber_withJSON       (json ["phone_number"]);
    set_username_withJSON          (json ["username"]);
    set_firstName_withJSON         (json ["first_name"]);
    set_lastName_withJSON          (json ["last_name"]);
    set_languageCode_withJSON      (json ["language_code"]);
    set_restrictionReason_withJSON (json ["restriction_reason"]);
    set_isVerified_withJSON        (json ["is_verified"]);
    set_haveAccess_withJSON        (json ["have_access"]);
    set_type_withJSON              (json ["type"],          &QtTdLibUserType::create);
    set_status_withJSON            (json ["status"],        &QtTdLibUserStatus::create);
    set_outgoingLink_withJSON      (json ["outgoing_link"], &QtTdLibLinkState::create);
    set_incomingLink_withJSON      (json ["incoming_link"], &QtTdLibLinkState::create);
    set_profilePhoto_withJSON      (json ["profile_photo"], &QtTdLibAbstractStrIdObject::create<QtTdLibProfilePhoto>);
}

QtTdLibUserType::QtTdLibUserType (const QtTdLibObjectType::Type typeOf, QObject * parent)
    : QtTdLibAbstractObject { typeOf, parent }
{ }

QtTdLibUserType * QtTdLibUserType::create (const QJsonObject & json, QObject * parent) {
    switch (QtTdLibEnums::objectTypeEnumFromJson (json)) {
        case QtTdLibObjectType::USER_TYPE_REGULAR: return new QtTdLibUserTypeRegular { parent };
        case QtTdLibObjectType::USER_TYPE_DELETED: return new QtTdLibUserTypeDeleted { parent };
        case QtTdLibObjectType::USER_TYPE_BOT:     return new QtTdLibUserTypeBot     { parent };
        case QtTdLibObjectType::USER_TYPE_UNKNOWN: return new QtTdLibUserTypeUnknown { parent };
        default: return Q_NULLPTR;
    }
}

QtTdLibUserTypeRegular::QtTdLibUserTypeRegular (QObject * parent)
    : QtTdLibUserType { QtTdLibObjectType::USER_TYPE_REGULAR, parent }
{ }

QtTdLibUserTypeDeleted::QtTdLibUserTypeDeleted (QObject * parent)
    : QtTdLibUserType { QtTdLibObjectType::USER_TYPE_DELETED, parent }
{ }

QtTdLibUserTypeBot::QtTdLibUserTypeBot (QObject * parent)
    : QtTdLibUserType { QtTdLibObjectType::USER_TYPE_BOT, parent }
{ }

QtTdLibUserTypeUnknown::QtTdLibUserTypeUnknown (QObject * parent)
    : QtTdLibUserType { QtTdLibObjectType::USER_TYPE_UNKNOWN, parent }
{ }

QtTdLibUserStatus::QtTdLibUserStatus (const QtTdLibObjectType::Type typeOf, QObject * parent)
    : QtTdLibAbstractObject { typeOf, parent }
{ }

QtTdLibUserStatus * QtTdLibUserStatus::create (const QJsonObject & json, QObject * parent) {
    switch (QtTdLibEnums::objectTypeEnumFromJson (json)) {
        case QtTdLibObjectType::USER_STATUS_EMPTY:      return new QtTdLibUserStatusEmpty     { parent };
        case QtTdLibObjectType::USER_STATUS_ONLINE:     return new QtTdLibUserStatusOnline    { parent };
        case QtTdLibObjectType::USER_STATUS_OFFLINE:    return new QtTdLibUserStatusOffline   { parent };
        case QtTdLibObjectType::USER_STATUS_RECENTLY:   return new QtTdLibUserStatusRecently  { parent };
        case QtTdLibObjectType::USER_STATUS_LAST_WEEK:  return new QtTdLibUserStatusLastWeek  { parent };
        case QtTdLibObjectType::USER_STATUS_LAST_MONTH: return new QtTdLibUserStatusLastMonth { parent };
        default: return Q_NULLPTR;
    }
}

QtTdLibUserStatusEmpty::QtTdLibUserStatusEmpty (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_EMPTY, parent }
{ }

QtTdLibUserStatusOnline::QtTdLibUserStatusOnline (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_ONLINE, parent }
{ }

QtTdLibUserStatusOffline::QtTdLibUserStatusOffline (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_OFFLINE, parent }
{ }

QtTdLibUserStatusRecently::QtTdLibUserStatusRecently (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_RECENTLY, parent }
{ }

QtTdLibUserStatusLastWeek::QtTdLibUserStatusLastWeek (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_LAST_WEEK, parent }
{ }

QtTdLibUserStatusLastMonth::QtTdLibUserStatusLastMonth (QObject * parent)
    : QtTdLibUserStatus { QtTdLibObjectType::USER_STATUS_LAST_MONTH, parent }
{ }
