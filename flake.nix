{
  description = "iam-alive-bot: Telegram activity monitor on userver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";

    # Declared here so userver-nix follows it and --override-input works.
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

  outputs = { self, nixpkgs, flake-utils, userver-src, userver-nix, tgbot-cpp-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        p = import ./nix/packages.nix {
          inherit pkgs userver-nix tgbot-cpp-src;
        };
      in {
        packages = {
          default = p.iam-alive-bot;
          iam-alive-bot = p.iam-alive-bot;
          iam-alive-bot-config = p.iam-alive-bot-config;
          tgbot-cpp = p.tgbot-cpp;
          set-webhook = p.setWebhook;
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "run-iam-alive-bot" ''
            exec ${pkgs.lib.getExe p.iam-alive-bot} \
              -c ${p.iam-alive-bot-config}/share/iam_alive_bot/static_config.yaml
          ''}";
        };

        apps.set-webhook = {
          type = "app";
          program = "${p.setWebhook}/bin/tgbot-set-webhook";
        };

        devShells.default = pkgs.clangStdenv.mkDerivation {
          name = "iam-alive-bot-dev";
          nativeBuildInputs = with pkgs; [
            cmake ninja pkg-config
            clang-tools
            gdb
          ];
          buildInputs = [ p.tgbot-cpp p.userver ];
          shellHook = ''
            echo "iam-alive-bot dev shell (clang)."
            echo "Configure: cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug"
          '';
        };
      })
    // {
      # System-independent outputs live OUTSIDE eachDefaultSystem.
      nixosModules.default = import ./nix/service.nix { inherit self; };
      nixosModules.iam-alive-bot = self.nixosModules.default;
    };
}
