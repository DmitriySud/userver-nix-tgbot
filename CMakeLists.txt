cmake_minimum_required(VERSION 3.20)
project(tgbot LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# userver: installed via the userver-nix flake, so config-mode find_package.
# Only the core component is needed (HTTP server, secdist, http client live there).
find_package(userver REQUIRED COMPONENTS core)

# tgbot-cpp: provided by the flake. Used only as a JSON/type parser.
# Try the modern CMake config target first; fall back to find_library.
find_package(TgBot REQUIRED)

# ---- shared object library: sources reused by service + (future) tests ----
add_library(${PROJECT_NAME}_objs OBJECT
    src/secdist.hpp
    src/secdist.cpp
    src/webhook_handler.hpp
    src/webhook_handler.cpp
)
target_include_directories(${PROJECT_NAME}_objs PUBLIC src)
target_link_libraries(${PROJECT_NAME}_objs PUBLIC userver::core)

target_link_libraries(${PROJECT_NAME}_objs PUBLIC TgBot)

# ---- the service executable ----
add_executable(${PROJECT_NAME} src/main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_objs)

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
