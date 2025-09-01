PORT ?= 5173
OPEN ?= 0

.PHONY: serve
serve:
	@echo "Starting local server on http://127.0.0.1:$(PORT) (OPEN=$(OPEN))"
	bash ./serve $(PORT) $(if $(filter $(OPEN),1),--open,)

