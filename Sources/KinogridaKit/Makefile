PROJECT   = Kinogrida.xcodeproj
SCHEME    = Kinogrida
BUILD_DIR = build

# Recursive header search — allows flat #import "KGBaseShape.h" from any subfolder
HEADERS = HEADER_SEARCH_PATHS='$$(inherited) $$(SRCROOT)/Kinogrida/**'

.PHONY: all debug release clean install remove

all: release

debug:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Debug \
		-derivedDataPath $(BUILD_DIR) $(HEADERS) build

release:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release \
		-derivedDataPath $(BUILD_DIR) $(HEADERS) build

clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean
	rm -rf $(BUILD_DIR)

install: release
	@# Tuer le processus qui a chargé l'ancien binaire (cache signature kernel)
	-killall legacyScreenSaver 2>/dev/null || true
	@# Supprimer l'ancien bundle pour invalider le cache du kernel
	rm -rf ~/Library/Screen\ Savers/Kinogrida.saver
	@# Copier le nouveau bundle
	cp -R $(BUILD_DIR)/Build/Products/Release/Kinogrida.saver \
		~/Library/Screen\ Savers/
	@# Re-signer ad-hoc pour garantir une signature fraîche
	codesign --force --deep -s - ~/Library/Screen\ Savers/Kinogrida.saver
	@echo "Installé dans ~/Library/Screen Savers/"

remove:
	rm -rf ~/Library/Screen\ Savers/Kinogrida.saver
	@echo "Supprimé de ~/Library/Screen Savers/"
