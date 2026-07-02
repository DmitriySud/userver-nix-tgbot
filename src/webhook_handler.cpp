#include "webhook_handler.hpp"

#include <tgbot/TgTypeParser.h>
#include <tgbot/types/Update.h>

#include <userver/components/component_context.hpp>
#include <userver/logging/log.hpp>
#include <userver/server/http/http_status.hpp>
#include <userver/storages/secdist/secdist.hpp>

#include "secdist.hpp"
#include "bot_component.hpp"

namespace tgbot {

WebhookHandler::WebhookHandler(
    const userver::components::ComponentConfig &config,
    const userver::components::ComponentContext &context)
    : HttpHandlerBase(config, context),
      bot_(context.FindComponent<BotComponent>()),
      expected_secret_path_(context.FindComponent<BotSecdist>().secret_path) {}

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

    TgBot::Update::Ptr update;
    try {
        // tgbot-cpp used purely as a parser: JSON string -> typed Update.
        TgBot::TgTypeParser parser;
        update = parser.parseJsonAndGetUpdate(parser.parseJson(request.RequestBody()));
    } catch (const std::exception& ex) {
        // Malformed payload: ack with 200 anyway so Telegram doesn't retry a
        // body we'll never parse. Log for visibility.
        LOG_WARNING() << "Failed to parse Telegram Update: " << ex.what();
        return {};
    }

    if (!update) {
        return {};
    }

    bot_.HandleUpdateAsync(std::move(update));

    // Always an empty 200 ack; replies are sent as outbound API calls.
    return {};
}

} // namespace tgbot
