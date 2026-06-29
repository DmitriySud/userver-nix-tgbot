#pragma once

#include <string>

#include <userver/formats/json/value.hpp>
#include <userver/storages/secdist/secdist.hpp>

namespace tgbot {

// Mirrors the JSON deployed at /run/secrets/tgbot-secdist:
//   { "telegram_bot_token": "...", "random_secret_token": "...", "secret_path": "..." }
struct BotSecdist {
    explicit BotSecdist(const userver::formats::json::Value& doc);

    std::string telegram_bot_token;
    std::string secret_path;
    // random_secret_token is intentionally not parsed: path-only scheme.
};

}  // namespace tgbot
