.PHONY: ci
ci: ## Run every clusterless gate
	@bash scripts/foo-check.sh
	@bash scripts/bar-check.sh

.PHONY: other
other: ## unrelated target — must not be scanned
	@bash scripts/unrelated.sh
