#pragma once

#include <userver/components/component_base.hpp>
#include <userver/concurrent/background_task_storage.hpp>
#include <tgbot/Bot.h>

#include "activity_repository.hpp"
#include "userver_http_client_wrapper.hpp"

class BotComponent final : public userver::components::ComponentBase {
public:
    static constexpr std::string_view kName = "bot";

    BotComponent(const userver::components::ComponentConfig& config,
                 const userver::components::ComponentContext& context);

    // used by the webhook handler
    void HandleUpdate(TgBot::Update::Ptr update) const {
        bot_.getEventHandler().handleUpdate(std::move(update));
    }

    // used by the poller AND by command handlers
    void SendMessage(std::int64_t chat_id, const std::string& text) const {
        bot_.getApi().sendMessage(chat_id, text);
    }

    void HandleUpdateAsync(TgBot::Update::Ptr update) const;

private:
    ActivityRepository& repo_;        // reference to the repo component
    UserverHttpClient tg_http_;       // declared BEFORE bot_ — must outlive it
    TgBot::Bot bot_;

    mutable userver::concurrent::BackgroundTaskStorage bts_;
};
