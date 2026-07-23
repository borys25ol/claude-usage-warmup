LABEL := com.claude-usage-warmup
LOG := $(HOME)/.claude/warmup.log

.DEFAULT_GOAL := help
.PHONY: help install uninstall test status logs

help: ## Show this help
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | \
	 awk -F':.*## ' '{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

install: ## Schedule the wake and load the LaunchAgent (RUN_TIME=HH:MM to override)
	@bash install-warmup.sh

uninstall: ## Remove the LaunchAgent and cancel the wake
	@bash uninstall-warmup.sh

test: ## Run the warmup once and show the log
	@bash claude-warmup.sh && tail "$(LOG)"

status: ## Show the pmset schedule and LaunchAgent state
	@pmset -g sched
	@echo
	@launchctl print gui/$$(id -u)/$(LABEL) 2>/dev/null | grep -E 'state|program' \
	 || echo "LaunchAgent $(LABEL) is not loaded."

logs: ## Tail the warmup log
	@tail -f "$(LOG)"
