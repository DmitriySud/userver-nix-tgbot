#include "webhook_handler.hpp"

#include <tgbot/types/Update.h>
#include <tgbot/TgTypeParser.h>

#include <userver/logging/log.hpp>
#include <userver/server/http/http_status.hpp>
#include <userver/storages/secdist/secdist.hpp>

#include "secdist.hpp"

namespace tgbot {

WebhookHandler::WebhookHandler(
    const userver::components::ComponentConfig& config,
    const userver::components::ComponentContext& context)
    : HttpHandlerBase(config, context) {
    const auto& secdist =
        context.FindComponent<userver::components::Secdist>().Get();
    expected_secret_path_ = secdist.Get<BotSecdist>().secret_path;
}

std::string WebhookHandler::HandleRequestThrow(
    const userver::server::http::HttpRequest& request,
    userver::server::request::RequestContext& /*context*/) const {
    // Obscurity gate: the path secret is the only auth. A miss looks like a
    // nonexistent route, giving scanners no signal.
    if (request.GetPathArg("secret_path") != expected_secret_path_) {
        request.GetHttpResponse().SetStatus(
            userver::server::http::HttpStatus::kNotFound);
        return {};
    }

    const std::string& body = request.RequestBody();

    TgBot::Update::Ptr update;
    try {
        // tgbot-cpp used purely as a parser: JSON string -> typed Update.
        TgBot::TgTypeParser parser;
        update = parser.parseJsonAndGetUpdate(parser.parseJson(body));
    } catch (const std::exception& ex) {
        // Malformed payload: ack with 200 anyway so Telegram doesn't retry a
        // body we'll never parse. Log for visibility.
        LOG_WARNING() << "Failed to parse Telegram Update: " << ex.what();
        return {};
    }

    if (update && update->message) {
        const auto& msg = update->message;
        // TODO: feed into inactivity tracker:
        //   repository_.RecordActivity(msg->chat->id, msg->from->id, now);
        LOG_INFO() << "message chat_id=" << msg->chat->id
                   << " user_id=" << (msg->from ? msg->from->id : 0);
    } else if (update && update->callbackQuery) {
        // TODO: callback-query access control + handling.
        LOG_INFO() << "callback_query";
    }

    // Telegram only needs a 200 OK with an empty (or method-call) body.
    return {};
}

}  // namespace tgbot
