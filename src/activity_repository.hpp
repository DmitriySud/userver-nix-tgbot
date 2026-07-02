#include <userver/components/component_context.hpp>
#include <userver/storages/sqlite/client.hpp>
#include <userver/storages/sqlite/component.hpp>

class ActivityRepository final : public userver::components::ComponentBase {
public:
  static constexpr std::string_view kName = "activity-repository";

  ActivityRepository(const userver::components::ComponentConfig &config,
                     const userver::components::ComponentContext &context)
      : ComponentBase(config, context),
        db_(context.FindComponent<userver::components::SQLite>("sqlite-db")
                .GetClient()) {
    db_->Execute(userver::storages::sqlite::OperationType::kReadWrite, R"(
            CREATE TABLE IF NOT EXISTS activity (
                chat_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                last_update_ts INTEGER NOT NULL,
                PRIMARY KEY (chat_id, user_id)
            ) WITHOUT ROWID
        )");
  }

  void Touch(std::int64_t chat_id, std::int64_t user_id, std::int64_t ts) {
    db_->Execute(userver::storages::sqlite::OperationType::kReadWrite, R"(
            INSERT INTO activity (chat_id, user_id, last_update_ts)
            VALUES (?, ?, ?)
            ON CONFLICT(chat_id, user_id)
            DO UPDATE SET last_update_ts = excluded.last_update_ts
        )",
                 chat_id, user_id, ts);
  }
  std::optional<std::int64_t> GetLastActivity(std::int64_t chat_id,
                                              std::int64_t user_id) {
    auto result = db_->Execute(
        userver::storages::sqlite::OperationType::kReadOnly,
        "SELECT last_update_ts FROM activity WHERE chat_id = ? AND user_id = ?",
        chat_id, user_id);
    return std::move(result).AsOptionalSingleField<std::int64_t>();
  }

private:
  userver::storages::sqlite::ClientPtr db_;
};
