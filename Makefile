.PHONY: build install uninstall clean release dmg bump-tap

APP_NAME = ClaudeCodeUsage
INSTALL_DIR = /Applications
VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")

build:
	@bash build-app.sh

install: build
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@cp -R $(APP_NAME).app $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"
	@open $(INSTALL_DIR)/$(APP_NAME).app

uninstall:
	@rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled $(APP_NAME)"

clean:
	@rm -rf .build $(APP_NAME).app $(APP_NAME).dmg
	@echo "Cleaned"

dmg: build
	@rm -f $(APP_NAME).dmg
	$(eval DMG_DIR := $(shell mktemp -d))
	@cp -R $(APP_NAME).app $(DMG_DIR)/
	@ln -s /Applications $(DMG_DIR)/Applications
	@hdiutil create -volname "Claude Code Usage" -srcfolder $(DMG_DIR) -ov -format UDZO $(APP_NAME).dmg
	@rm -rf $(DMG_DIR)
	@echo "Created $(APP_NAME).dmg"

release:
	@if [ -z "$(v)" ]; then echo "Usage: make release v=1.0.0"; exit 1; fi
	@echo "Releasing v$(v)..."
	@sed -i '' 's|<string>[0-9]*\.[0-9]*\.[0-9]*</string>|<string>$(v)</string>|g' ClaudeCodeUsage/Sources/App/Info.plist
	@git add ClaudeCodeUsage/Sources/App/Info.plist
	@git commit -m "release: v$(v)"
	@git tag v$(v)
	@git push && git push origin v$(v)
	@$(MAKE) dmg
	@gh release create v$(v) $(APP_NAME).dmg --title "v$(v)" --generate-notes
	@$(MAKE) bump-tap v=$(v)
	@rm -f $(APP_NAME).dmg
	@echo "Released v$(v)"

bump-tap:
	@if [ -z "$(v)" ]; then echo "Usage: make bump-tap v=1.0.0"; exit 1; fi
	$(eval SHA := $(shell curl -sL "https://github.com/sasha-computer/claude-code-usage/releases/download/v$(v)/$(APP_NAME).dmg" | shasum -a 256 | cut -d' ' -f1))
	$(eval TAP_DIR := $(shell mktemp -d))
	@git clone --depth 1 git@github.com:sasha-computer/homebrew-tap.git $(TAP_DIR)
	@sed -i '' 's|version ".*"|version "$(v)"|' $(TAP_DIR)/Casks/claude-code-usage.rb
	@sed -i '' 's|sha256 ".*"|sha256 "$(SHA)"|' $(TAP_DIR)/Casks/claude-code-usage.rb
	@cd $(TAP_DIR) && git add -A && git commit -m "bump claude-code-usage to v$(v)" && git push
	@rm -rf $(TAP_DIR)
	@echo "Updated homebrew tap to v$(v)"
