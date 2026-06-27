{
  description = "Telegram bot hello example based on userver framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";

    # Declare userver-src here, so userver-nix can follow it 
    # and we can use --override-input userver-src /home/...
    # while building hello-service in this repo
    userver-src = {
      url = "github:userver-framework/userver/v3.0";
      flake = false;
    };

    userver-nix = {
      url = "github:DmitriySud/userver-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.userver-src.follows = "userver-src";
    };

    tgbot-cpp-src = {
      url = "github:reo7sp/tgbot-cpp/v1.8";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, userver-src, userver-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        userver = userver-nix.lib.${system}.mkUserver {
          features = { core = true; };
        };

        tgbot-cpp = import ./tgbot-cpp.nix {
          inherit pkgs;
          version = "1.8";
          src = tgbot-cpp-src;
        };

        # Use the clang stdenv as requested.
        clangStdenv = pkgs.clangStdenv;

        hello-tgbot = clangStdenv.mkDerivation {
          pname = "hello-tgbot";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ cmake ninja pkg-config python3 ];

          buildInputs = [
            tgbot-cpp
            userver
          ];

          # Point find_package(userver ...) at the wrapper's installed package.
          cmakeFlags = [
            "-Duserver_DIR=${userver}/lib/cmake/userver"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DUSERVER_FEATURE_TESTSUITE=OFF"
          ];

          meta = with pkgs.lib; {
            description = "Minimal userver HTTP service that says hello";
            license = licenses.asl20;
            platforms = platforms.linux;
            mainProgram = "hello_service";
          };
        };
      in {
        packages = {
          default = hello-tgbot;
          hello-tgbot = hello-tgbot;
        };

        apps.default = {
          type = "app";
          # The bot reads the token from $TELEGRAM_BOT_TOKEN at runtime.
          program = "${pkgs.writeShellScript "run-hello-tgbot" ''
            if [ -z "''${TELEGRAM_BOT_TOKEN:-}" ]; then
              echo "Set TELEGRAM_BOT_TOKEN before running." >&2
              exit 1
            fi
            exec ${hello-tgbot}/bin/hello_tgbot \
              -c ${hello-tgbot}/share/hello_tgbot/static_config.yaml
          ''}";
        };

        devShells.default = clangStdenv.mkDerivation {
          name = "hello-tgbot-dev";
          nativeBuildInputs = with pkgs; [
            cmake ninja pkg-config
            clang-tools   # clangd / clang-format
            gdb
          ];
          buildInputs = [ tgbot-cpp ];
          shellHook = ''
            echo "hello-tgbot dev shell (clang). tgbot-cpp available."
            echo "Configure: cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug"
          '';
        };
      });
}
