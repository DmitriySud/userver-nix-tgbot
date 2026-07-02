#pragma once 
#include <userver/utils/datetime.hpp>

inline std::string FormatUtc(std::int64_t unix_ts) {
    return userver::utils::datetime::Timestring(
        std::chrono::system_clock::time_point{std::chrono::seconds{unix_ts}},
        "UTC", "%Y-%m-%d %H:%M:%S UTC");
}
