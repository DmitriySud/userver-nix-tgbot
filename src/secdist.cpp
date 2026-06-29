#include "secdist.hpp"

namespace tgbot {

BotSecdist::BotSecdist(const userver::formats::json::Value& doc)
    : telegram_bot_token(doc["telegram_bot_token"].As<std::string>()),
      secret_path(doc["secret_path"].As<std::string>()) {}

}  // namespace tgbot
