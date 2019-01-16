.PHONY: help frontend-install frontend-build frontend-bundle server-build server-install
.DEFAULT_GOAL := help

export

SERVER_PORT ?= 8081
SERVER_HOST ?= localhost
SERVER_BASE_URL ?= $(SERVER_HOST):$(SERVER_PORT)

BACKEND ?= core
PS_DIRS ?=  "./staging/$(BACKEND)/.psc-package/*/*/*/src/**/*.purs"

help: ## Ask for help!
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

frontend-install: ## install frontend dependencies
	npm i; bower i;

frontend-build: ## build the frontent
	pulp build

frontend-bundle: ## bundle the frontend;
	SERVER_BASE_URL='$${SERVER_BASE_URL}' ./node_modules/.bin/webpack

frontend-serve: ## serve the frontend;
	./node_modules/.bin/webpack-dev-server

server-build: ## install server dependencies and build
	stack build

server-install: ## install the server executables
	stack install

server-run: ## run the server
	stack install; stack exec -- trypurescript $(SERVER_PORT) $(PS_DIRS)
