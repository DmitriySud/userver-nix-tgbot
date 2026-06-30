#include <userver/clients/http/component_core.hpp>
#include <userver/components/minimal_server_component_list.hpp>
#include <userver/utils/daemon_run.hpp>

#include <userver/clients/dns/component.hpp>
#include <userver/clients/http/component.hpp>
#include <userver/storages/secdist/component.hpp>
#include <userver/storages/secdist/provider_component.hpp>

#include "webhook_handler.hpp"

int main(int argc, char* argv[]) {
    const auto component_list =
        userver::components::MinimalServerComponentList()
            .Append<userver::components::Secdist>()
            .Append<userver::components::DefaultSecdistProvider>()
            .Append<userver::clients::dns::Component>()
            .Append<userver::components::HttpClient>()
            .Append<userver::components::HttpClientCore>()
            .Append<tgbot::WebhookHandler>();

    return userver::utils::DaemonMain(argc, argv, component_list);
}
