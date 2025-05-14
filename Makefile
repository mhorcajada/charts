# ----------------------------------------
# Makefile para publicar Helm Chart mhorcajada/storj-gateway
# ----------------------------------------

CHART_NAME      := storj-gateway
CHART_DIR       := $(CHART_NAME)
CHART_VERSION   ?= $(shell grep '^version:' $(CHART_DIR)/Chart.yaml | awk '{print $$2}')
REPO_URL        := https://mhorcajada.github.io/charts
DIST_DIR        := /tmp/chart-release

.PHONY: help lint template install package index save-artifacts push-main push-gh-pages create-tag release clean-cache sync-index

help: ## 📖 Muestra esta ayuda con soporte multilínea
	@echo "📘 Objetivos disponibles:"
	@awk ' \
		BEGIN {FS = ":.*?## "}; \
		/^[a-zA-Z0-9_-]+:.*?## / { \
			cmd = $$1; desc = $$2; \
			printf "\033[36m%-20s\033[0m - %s\n", cmd, desc; \
		} \
		/^[ \t]*##/ && !/^[a-zA-Z0-9_-]+:.*?## / { \
			sub(/^[ \t]*##[ \t]*/, "", $$0); \
			print "                     " $$0; \
		} \
	' $(MAKEFILE_LIST)

precheck: ## 🛡 Verifica que la versión sea nueva respecto a la publicada en GitHub Pages
	@echo "🌐 Verificando versión remota de $(CHART_NAME) en $(REPO_URL)/index.yaml..."
	@LATEST_VERSION=$$(curl -s $(REPO_URL)/index.yaml | yq ".entries.\"$(CHART_NAME)\".[].version" | head -1 | tr -d '"'); \
	if [ -z "$$LATEST_VERSION" ]; then \
		echo "❌ No se pudo obtener la versión desde $(REPO_URL)/index.yaml"; \
		exit 1; \
	fi; \
	if [ "$(CHART_VERSION)" = "$$LATEST_VERSION" ]; then \
		echo "⚠️  La versión $(CHART_VERSION) ya está publicada (coincide con $$LATEST_VERSION). Aborta."; \
		exit 1; \
	fi; \
	echo "✅ Versión nueva detectada: $(CHART_VERSION) > $$LATEST_VERSION"

test: ## 🔧 Muestra el valor actual de las variables usadas en el release
	@echo "🔍 VARIABLES ACTUALES:"
	@echo "------------------------------"
	@echo "📦 CHART_NAME    = $(CHART_NAME)"
	@echo "📂 CHART_DIR     = $(CHART_DIR)"
	@echo "🏷 CHART_VERSION = $(CHART_VERSION)"
	@echo "🌐 REPO_URL      = $(REPO_URL)"
	@echo "📁 DIST_DIR      = $(DIST_DIR)"
	@echo "------------------------------"
	@echo "Recuerda ejecuta make precheck"
	@echo "------------------------------"

lint: ## ✅ Valida el chart
	helm lint $(CHART_DIR)

template: ## 🔍 Renderiza manifest con template
	helm template $(CHART_NAME) ./$(CHART_DIR) -f $(CHART_DIR)/values.yaml

install: ## 🚀 Simula instalación (--dry-run --debug)
	helm install $(CHART_NAME)-test ./$(CHART_DIR) -f $(CHART_DIR)/values.yaml --dry-run --debug

update-readme-version: ## 📝 Sustituye versión en README.md si CHART_VERSION > LATEST_VERSION
	@LATEST_VERSION=$$(curl -s $(REPO_URL)/index.yaml | yq '.entries["$(CHART_NAME)"][0].version' | tr -d '"'); \
	if [ -z "$$LATEST_VERSION" ]; then \
		echo "❌ No se pudo obtener la versión remota desde $(REPO_URL)/index.yaml"; exit 1; \
	fi; \
	if dpkg --compare-versions "$(CHART_VERSION)" gt "$$LATEST_VERSION"; then \
		echo "🔁 Actualizando README.md de $$LATEST_VERSION → $(CHART_VERSION)..."; \
		sed -i "s/$$LATEST_VERSION/$(CHART_VERSION)/g" $(CHART_DIR)/README.md; \
	else \
		echo "✅ README.md ya contiene la última versión: $(CHART_VERSION)"; \
	fi

package: ## 📦 Empaqueta el chart
	helm package $(CHART_DIR) --version $(CHART_VERSION) --destination .

index: ## 🔃 Regenera el index.yaml
	helm repo index . --url $(REPO_URL)

save-artifacts: ## 💾 Copia .tgz, index y README.md al directorio temporal
	@mkdir -p $(DIST_DIR)
	mv $(CHART_NAME)-$(CHART_VERSION).tgz $(DIST_DIR)/
	cp README.md $(DIST_DIR)/

push-main: ## ⬆️  Sube el release a main si hay cambios antes de saltar a gh-pages
	git add README.md
	git add storj-gateway/Chart.yaml
	git add storj-gateway/README.md
	(git commit -m "release($(CHART_NAME)): publish chart v$(CHART_VERSION)" && git push) || echo "ℹ️ Nada que commitear"

push-gh-pages: ## 🚀 Sube a gh-pages los artefactos necesarios
	@echo "🚀 Subiendo $(CHART_NAME)-$(CHART_VERSION).tgz al branch gh-pages..."
	@git checkout gh-pages
	mv $(DIST_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz .
	mv $(DIST_DIR)/README.md .
	helm repo index . --url $(REPO_URL)
	git add -f $(CHART_NAME)-$(CHART_VERSION).tgz
	git add index.yaml
	git add README.md
	git commit -m "release($(CHART_NAME)): publish chart v$(CHART_VERSION)" || echo "ℹ️ Nada que commitear"
	git push origin gh-pages
	git checkout main

create-tag: ## 🏷️  Crea el tag si no existe y lo sube
	@if git rev-parse "v$(CHART_VERSION)" >/dev/null 2>&1; then \
		echo "🔖 Tag v$(CHART_VERSION) ya existe. No se crea otro."; \
	else \
		echo "🏷️  Creando tag v$(CHART_VERSION)..."; \
		git tag -a v$(CHART_VERSION) -m "release($(CHART_NAME)): v$(CHART_VERSION)"; \
		git push origin v$(CHART_VERSION); \
	fi

clean-cache: ## 🧹 Elimina el índice cacheado local
	@echo "🧹 Limpiando caché local de Helm..."
	rm -f ~/.cache/helm/repository/mhorcajada-index.yaml

sync-index: clean-cache ## 🔄 Refresca el repo Helm local
	@echo "🔄 Refrescando repositorio Helm local..."
	helm repo remove mhorcajada || true
	helm repo add mhorcajada $(REPO_URL)
	sleep 1
	helm repo update
	sleep 5
	helm search repo mhorcajada/$(CHART_NAME) --versions

release:  precheck lint template update-readme-version package save-artifacts push-main push-gh-pages create-tag sync-index ## 📦 Publica el chart completo. Uso: make release CHART_VERSION=0.x.x   y   make release
	@echo "\n✅ Publicación completada:"
	@echo "🔗 Chart URL: $(REPO_URL)/$(CHART_NAME)-$(CHART_VERSION).tgz"
	@echo "📦 Añade el repo con:"
	@echo "    helm repo add mhorcajada $(REPO_URL)"
	@echo "    helm repo update"
	@echo "🔍 Búscalo con:"
	@echo "    helm search repo mhorcajada/$(CHART_NAME)"
	@echo "🚀 Instálalo con:"
	@echo "    helm install $(CHART_NAME) mhorcajada/$(CHART_NAME) --version $(CHART_VERSION)"
