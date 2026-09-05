# base Build Makefile
# Provides targets for localization, proto code generation and clean builds.

.PHONY: help l10n proto clean pub-get

help: ## Display this help message
	@echo "base Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help                    Show this help message"
	@echo "  l10n                    Generate localization files from ARB"
	@echo "  proto                   Generate Dart code from .proto files"
	@echo "  clean                   Clean build artifacts"
	@echo "  pub-get                 Run flutter pub get"
	@echo ""

# ---------------------------------------------------------------------------
# Localization
# ---------------------------------------------------------------------------
.PHONY: l10n
l10n: ## Generate localization files from ARB
	@echo "Generating localization files..."
	@if [ ! -d "lib/l10n/arb" ]; then \
		echo "ERROR: lib/l10n/arb directory not found"; \
		exit 1; \
	fi
	@if [ -z "$$(ls -A lib/l10n/arb/*.arb 2>/dev/null)" ]; then \
		echo "ERROR: No .arb files found in lib/l10n/arb/"; \
		exit 1; \
	fi
	flutter gen-l10n \
		--arb-dir=lib/l10n/arb \
		--output-dir=lib/l10n/generated \
		--template-arb-file=app_ar.arb \
		--output-localization-file=app_localizations.dart
	@echo "✓ Localization files generated in lib/l10n/generated/"

# ---------------------------------------------------------------------------
# Protocol Buffers / gRPC code generation
# ---------------------------------------------------------------------------
.PHONY: proto
proto: ## Generate Dart code from .proto files in protos/
	@echo "Generating Dart code from proto files..."
	@if [ ! -d "protos" ]; then \
		echo "ERROR: protos/ directory not found"; \
		exit 1; \
	fi
	@if [ -z "$$(ls -A protos/*.proto 2>/dev/null)" ]; then \
		echo "ERROR: No .proto files found in protos/"; \
		exit 1; \
	fi
	@# Create the output directory for generated code
	mkdir -p lib/core/network/generated
	@# Determine the protoc include path for standard .proto files.
	@# Homebrew installs them under /opt/homebrew/include (Apple Silicon)
	@# or /usr/local/include (Intel). Fallback to empty if not found.
	PROTO_INC=$$(ls -d /opt/homebrew/Cellar/protobuf/*/include 2>/dev/null | head -1); \
	if [ -z "$$PROTO_INC" ]; then PROTO_INC=$$(ls -d /usr/local/include 2>/dev/null | head -1); fi; \
	for proto_file in protos/*.proto; do \
		echo "  Generating from $$proto_file ..."; \
		protoc --dart_out=grpc:lib/core/network/generated \
			-I protos \
			$(if $$PROTO_INC,-I $$PROTO_INC,) \
			$$proto_file; \
	done
	@echo "✓ Proto files generated in lib/core/network/generated/"

# ---------------------------------------------------------------------------
# pub get
# ---------------------------------------------------------------------------
.PHONY: pub-get
pub-get: ## Run flutter pub get
	@echo "Running flutter pub get..."
	flutter pub get
	@echo "✓ Dependencies resolved."

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
.PHONY: clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	flutter clean
	@echo "✓ Clean complete."

# Default target
all: l10n proto pub-get
