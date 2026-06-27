# tgbot-cpp.nix
# A from-source build of reo7sp/tgbot-cpp.
# Mirrors the upstream CMake install: produces lib + headers + cmake package files.
{ pkgs
, version ? "1.8"
, src ? null   # optionally override with a flake input (see flake.nix)
}:

let
  lib = pkgs.lib;
in
pkgs.stdenv.mkDerivation {
  pname = "tgbot-cpp";
  inherit version;

  src =
    if src != null then src
    else pkgs.fetchFromGitHub {
      owner = "reo7sp";
      repo = "tgbot-cpp";
      rev = "v${version}";
      # Replace with the real hash: run `nix build` once and copy the
      # "got:" hash from the error, or use nix-prefetch-github.
      hash = lib.fakeHash;
    };

  nativeBuildInputs = with pkgs; [ cmake pkg-config ];

  # These must be propagated so downstream consumers (hello-bot) get them
  # transitively via find_package(tgbot-cpp) — tgbot-cpp's headers and its
  # cmake targets reference Boost/OpenSSL/curl.
  propagatedBuildInputs = with pkgs; [
    boost
    openssl
    zlib
  ];

  # tgbot-cpp's CMakeLists installs a tgbot-cppConfig.cmake by default.
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DENABLE_TESTS=OFF"
  ];

  meta = with lib; {
    description = "C++ library for Telegram bot API";
    homepage = "https://github.com/reo7sp/tgbot-cpp";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
