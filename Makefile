# ---- config: edit these ----
VPS      ?= dsudakov@lastochka
CODE_ATTR    ?= hello-tgbot
CONFIG_ATTR  ?= hello-tgbot-config
# ----------------------------

CODE_LINK   := ./result
CONFIG_LINK := ./result-config

BIN     = $(shell readlink -f $(CODE_LINK))/bin/tgbot
CONFIG  = $(shell readlink -f $(CONFIG_LINK))/share/hello_tgbot/static_config.yaml

.PHONY: build build-config copy copy-config run deploy config-deploy set-webhook clean

## build the C++ service locally
build:
	nix build .#$(CODE_ATTR) -o $(CODE_LINK)

## build the config (fast, no compiler)
build-config:
	nix build .#$(CONFIG_ATTR) -o $(CONFIG_LINK)

## copy code closure to the VPS
copy: build
	nix copy --to ssh://$(VPS) --substitute-on-destination $$(readlink -f $(CODE_LINK))

## copy config closure to the VPS
copy-config: build-config
	nix copy --to ssh://$(VPS) --substitute-on-destination $$(readlink -f $(CONFIG_LINK))

## run on the VPS with both paths wired
run:
	ssh -t $(VPS) '$(BIN) -c $(CONFIG)'

## full: build+copy both, then run
deploy: copy copy-config run

## config-only loop: rebuild+copy just the config, then run
config-deploy: copy-config run

set-webhook:
	ssh $(VPS) 'TGBOT_HOST=$(HOST) nix run .#set-webhook'

clean:
	rm -f $(CODE_LINK) $(CONFIG_LINK)
