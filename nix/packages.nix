# Everything about building: deps, compilers, derivations.
# Pure function of pkgs + sources; knows nothing about deployment.
{ pkgs, userver-nix, tgbot-cpp-src }:

let
  clangStdenv = pkgs.clangStdenv;
  fs = pkgs.lib.fileset;

  userver = userver-nix.lib.${pkgs.system}.mkUserver {
    features = {
      core = true;
      sqlite = true;
    };
  };

  tgbot-cpp = import ./tgbot-cpp.nix {
    inherit pkgs;
    version = "1.8";
    src = tgbot-cpp-src;
  };

  root = ../.;
  botSources = fs.toSource {
    inherit root;
    fileset = fs.unions [
      (root + "/src")
      (root + "/CMakeLists.txt")
      # add whatever else the build reads: cmake/ modules, proto/, etc.
    ];
  };

  # Config-only derivation: pure file copy, no compiler, rebuilds instantly.
  # Editing configs/static_config.yaml invalidates ONLY this path.
  iam-alive-bot-config = pkgs.runCommand "iam-alive-bot-config" { } ''
    mkdir -p $out/share/iam_alive_bot
    cp ${../configs/static_config.yaml} $out/share/iam_alive_bot/static_config.yaml
  '';

  iam-alive-bot = clangStdenv.mkDerivation {
    pname = "iam-alive-bot";
    version = "0.1.0";
    src = botSources;

    nativeBuildInputs = with pkgs; [ cmake ninja pkg-config python3 ];

    buildInputs = [
      tgbot-cpp
      userver
    ];

    cmakeFlags = [
      "-Duserver_DIR=${userver}/lib/cmake/userver"
      "-DCMAKE_BUILD_TYPE=Release"
      "-DUSERVER_FEATURE_TESTSUITE=OFF"
    ];

    meta = with pkgs.lib; {
      description = "Telegram family-chat activity monitor bot";
      license = licenses.asl20;
      platforms = platforms.linux;
      mainProgram = "iam-alive-bot";
    };
  };

  setWebhook = import ./set-webhook.nix { inherit pkgs; };
in {
  inherit iam-alive-bot iam-alive-bot-config tgbot-cpp setWebhook userver;
}
