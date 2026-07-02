#pragma once

#include <string>

#include <userver/server/handlers/http_handler_base.hpp>

class BotComponent;

namespace tgbot {


class WebhookHandler final
    : public userver::server::handlers::HttpHandlerBase {
public:
    static constexpr std::string_view kName = "tgbot-webhook-handler";

    WebhookHandler(const userver::components::ComponentConfig& config,
                   const userver::components::ComponentContext& context);

    std::string HandleRequestThrow(
        const userver::server::http::HttpRequest& request,
        userver::server::request::RequestContext& context) const override;

private:
    BotComponent& bot_;
    std::string expected_secret_path_;
};

}  // namespace tgbot
