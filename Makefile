.PHONY: build install uninstall clean release

APP_NAME = CCUsage
INSTALL_DIR = /Applications

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
	@rm -rf .build $(APP_NAME).app
	@echo "Cleaned"

release: build
	@cd $(APP_NAME).app/.. && ditto -c -k --keepParent $(APP_NAME).app $(APP_NAME).zip
	@echo "Created $(APP_NAME).zip"
