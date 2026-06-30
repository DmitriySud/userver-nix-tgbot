#pragma once

#include <string>

#include <userver/components/component_context.hpp>
#include <userver/server/handlers/http_handler_base.hpp>
#include <userver/storages/secdist/component.hpp>

namespace tgbot {

class WebhookHandler final : public userver::server::handlers::HttpHandlerBase {
public:
    static constexpr std::string_view kName = "tgbot-webhook-handler";

    WebhookHandler(const userver::components::ComponentConfig& config,
                   const userver::components::ComponentContext& context);

    std::string HandleRequestThrow(
        const userver::server::http::HttpRequest& request,
        userver::server::request::RequestContext& context) const override;

private:
    // Cached at construction; secret_path is static for the process lifetime.
    std::string expected_secret_path_;
};

}  // namespace tgbot
