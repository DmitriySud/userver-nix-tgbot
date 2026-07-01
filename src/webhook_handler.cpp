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

        // Only respond to text messages; everything else gets an empty 200 ack.
    if (!update || !update->message || update->message->text.empty()) {
        return {};
    }

    const auto chat_id = update->message->chat->id;
    const auto& text = update->message->text;

    // Build the webhook-response method call:
    //   {"method":"sendMessage","chat_id":<id>,"text":"Hello <text>"}
    userver::formats::json::ValueBuilder reply;
    reply["method"] = "sendMessage";
    reply["chat_id"] = chat_id;
    reply["text"] = "Hello " + text;

    auto& response = request.GetHttpResponse();
    response.SetContentType(userver::http::content_type::kApplicationJson);
    return userver::formats::json::ToString(reply.ExtractValue());
}

}  // namespace tgbot
