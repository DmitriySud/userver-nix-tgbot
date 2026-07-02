#include <tgbot/net/HttpClient.h>
#include <tgbot/net/HttpReqArg.h>
#include <tgbot/net/Url.h>
#include <userver/clients/http/client.hpp>
#include <userver/clients/http/form.hpp>
#include <userver/http/url.hpp>

class UserverHttpClient final : public TgBot::HttpClient {
public:
  explicit UserverHttpClient(userver::clients::http::Client &client)
      : client_(client) {}

  std::string
  makeRequest(const TgBot::Url &url,
              const std::vector<TgBot::HttpReqArg> &args) const override {
    const std::string full_url = url.protocol + "://" + url.host + url.path;

    auto request = client_.CreateRequest()
                       .url(full_url)
                       .timeout(std::chrono::seconds{10})
                       .retry(2);

    if (args.empty()) {
      request.get();
    } else {
      const bool has_file = std::any_of(args.begin(), args.end(),
                                        [](const auto &a) { return a.isFile; });

      if (has_file) {
        // multipart/form-data — build a userver Form
        userver::clients::http::Form form;
        for (const auto &a : args) {
          if (a.isFile) {
            form.AddBuffer(
                a.name, a.fileName,
                std::make_shared<std::string>(a.value) /* bytes copy */,
                a.mimeType);
          } else {
            form.AddContent(a.name, a.value);
          }
        }
        request.form(std::move(form));
      } else {
        // application/x-www-form-urlencoded
        std::string body;
        for (const auto &a : args) {
          if (!body.empty())
            body += '&';
          body += userver::http::UrlEncode(a.name);
          body += '=';
          body += userver::http::UrlEncode(a.value);
        }
        request.data(std::move(body))
            .headers({{"Content-Type", "application/x-www-form-urlencoded"}});
      }
    }

    auto response = request.perform();
    response->raise_for_status(); // optional; tgbot expects raw body
    return std::move(*response).body();
  }

private:
  userver::clients::http::Client &client_;
};
