.PHONY: build install uninstall clean release

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
	@rm -f $(APP_NAME).dmg
	@echo "Released v$(v)"
