.PHONY: help frontend-install frontend-build frontend-bundle server-build server-install
.DEFAULT_GOAL := help

SERVER_PORT ?= 8081
SERVER_BASE_URL ?= localhost

help: ## Ask for help!
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

frontend-install: ## install frontend dependencies
	npm i; bower i;

frontend-build: ## build the frontent
	pulp build -- --censor-lib --strict

frontend-bundle: ## bundle the frontend and open in browser;
	pulp build -O --to js/index.js && open index.html

server-build: ## install server dependencies and build
	stack build

server-install: ## install the server executables
	stack install

server-run: ## run the server
	stack install; stack exec -- trypurescript $(SERVER_PORT) 
