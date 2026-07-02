#include "bot_component.hpp"
#include "secdist.hpp"
#include "utils.hpp"

#include <userver/clients/http/component.hpp>
#include <userver/logging/log.hpp>

BotComponent::BotComponent(const userver::components::ComponentConfig &config,
                           const userver::components::ComponentContext &context)
    : ComponentBase(config, context),
      repo_(context.FindComponent<ActivityRepository>()),
      tg_http_(context.FindComponent<userver::components::HttpClient>()
                   .GetHttpClient()),
      bot_(context.FindComponent<tgbot::BotSecdist>().telegram_bot_token) {

  bot_.getEvents().onCommand("last_activity", [this](TgBot::Message::Ptr m) {
    auto ts = repo_.GetLastActivity(m->chat->id, m->from->id);
    bot_.getApi().sendMessage(m->chat->id,
                              ts ? FormatUtc(*ts) : "No activity yet");
  });

  bot_.getEvents().onAnyMessage([this](TgBot::Message::Ptr m) {
    if (StringTools::startsWith(m->text, "/"))
      return; // commands handled above
    repo_.Touch(m->chat->id, m->from->id, m->date);
  });
}

void BotComponent::HandleUpdateAsync(TgBot::Update::Ptr update) const {
  bts_.AsyncDetach("tg-update", [this, update = std::move(update)] {
    try {
      bot_.getEventHandler().handleUpdate(update);
    } catch (const std::exception &ex) {
      LOG_ERROR() << "Update handling failed: " << ex.what();
    }
  });
}
