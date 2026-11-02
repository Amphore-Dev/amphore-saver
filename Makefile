PROJECT        = amphore-saver.xcodeproj
BUILD_DIR      = build
PRODUCTS       = $(BUILD_DIR)/Build/Products/Release
DIST           = dist
SAVERS_DIR     = $(HOME)/Library/Screen Savers

# Scheme → product (.saver) names
SCHEMES        = AmphoreSaver Kinogrida Shades Psykala
SAVERS         = amphore-saver Kinogrida Shades Psykala

# `make install SAVER=Shades` installs a single saver
SAVER         ?= $(SAVERS)

# Release signing / notarization
SIGN_ID       ?= Developer ID Application: Siméon Ferrara (JTV45F2TPG)
NOTARY_PROFILE ?= amphore

.PHONY: all project build install remove release clean refresh-settings

all: build

project:
	xcodegen generate --quiet

build: project
	@for scheme in $(SCHEMES); do \
		xcodebuild -project $(PROJECT) -scheme $$scheme -configuration Release \
			-destination 'generic/platform=macOS' -derivedDataPath $(BUILD_DIR) \
			-quiet build || exit 1; \
	done
	@echo "Built: $(addsuffix .saver,$(SAVERS))"

install: build
	@# Le processus hôte garde l'ancien binaire en cache
	-killall legacyScreenSaver 2>/dev/null || true
	@mkdir -p "$(SAVERS_DIR)"
	@for saver in $(SAVER); do \
		rm -rf "$(SAVERS_DIR)/$$saver.saver"; \
		cp -R "$(PRODUCTS)/$$saver.saver" "$(SAVERS_DIR)/"; \
		codesign --force -s - "$(SAVERS_DIR)/$$saver.saver"; \
		echo "Installed $$saver.saver"; \
	done
	@$(MAKE) --no-print-directory refresh-settings

# System Settings caches screensaver bundles (WallpaperAgent) and their
# thumbnails (on disk, never invalidated): a saver first seen without a
# valid thumbnail keeps the generic placeholder forever. Clear both.
THUMBNAIL_CACHE = $(shell getconf DARWIN_USER_CACHE_DIR)com.apple.wallpaper.extension.legacy/com.apple.wallpaper.legacy.thumbnails

refresh-settings:
	@test -d "$(THUMBNAIL_CACHE)" && find "$(THUMBNAIL_CACHE)" -name '*.png' -delete || true
	-@killall WallpaperLegacyExtension WallpaperAgent 2>/dev/null || true
	@echo "System Settings caches cleared: reopen System Settings"

remove:
	-killall legacyScreenSaver 2>/dev/null || true
	@for saver in $(SAVER); do \
		rm -rf "$(SAVERS_DIR)/$$saver.saver"; \
		echo "Removed $$saver.saver"; \
	done

# Signs with Developer ID, notarizes and staples every saver into dist/.
# One-time setup:
#   xcrun notarytool store-credentials amphore --apple-id <email> --team-id JTV45F2TPG
release: build
	rm -rf $(DIST) && mkdir -p $(DIST)
	@for saver in $(SAVERS); do \
		echo "── $$saver"; \
		cp -R "$(PRODUCTS)/$$saver.saver" $(DIST)/ && \
		codesign --force --options runtime --timestamp -s "$(SIGN_ID)" "$(DIST)/$$saver.saver" && \
		ditto -c -k --keepParent "$(DIST)/$$saver.saver" "$(DIST)/$$saver-notarize.zip" && \
		xcrun notarytool submit "$(DIST)/$$saver-notarize.zip" --keychain-profile "$(NOTARY_PROFILE)" --wait && \
		xcrun stapler staple "$(DIST)/$$saver.saver" && \
		rm "$(DIST)/$$saver-notarize.zip" && \
		ditto -c -k --keepParent "$(DIST)/$$saver.saver" "$(DIST)/$$saver.saver.zip" || exit 1; \
	done
	@ls -1 $(DIST)/*.zip

clean:
	rm -rf $(BUILD_DIR) $(DIST) $(PROJECT)
