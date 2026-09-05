#!/bin/bash
# Proto generation script for Flutter gRPC projects
# Usage: ./scripts/gen_proto.sh [proto_file]
#   Without args: regenerates all .proto files in protos/
#   With arg: generates only the specified proto file
#
# After generation, run:
#   flutter pub get
#
# The generated files support fromBuffer/writeToBuffer for serialization.
# Well-known types (timestamp, empty, etc.) are also generated for buffer support.

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

PROTO_DIR="protos"
OUTPUT_DIR="lib/core/network/generated"
PROTOC_GEN_DART="$HOME/.pub-cache/bin/protoc-gen-dart"

# Find protoc executable
if ! command -v protoc &> /dev/null; then
    echo "❌ protoc not found. Install it with:"
    echo "   brew install protobuf"
    exit 1
fi

# Find protoc include path for standard .proto files
PROTO_INC=""
if [ -d "/opt/homebrew/Cellar/protobuf" ]; then
    PROTO_INC="$(ls -d /opt/homebrew/Cellar/protobuf/*/include | head -1)"
elif [ -d "/usr/local/include" ]; then
    PROTO_INC="/usr/local/include"
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Check protoc-gen-dart exists
if [ ! -f "$PROTOC_GEN_DART" ]; then
    echo "❌ protoc-gen-dart not found at $PROTOC_GEN_DART"
    echo "   Install it with: dart pub global activate protoc_plugin 22.5.0"
    echo "   Then add ~/.pub-cache/bin to your PATH"
    exit 1
fi

# Function to generate Dart code from a single proto file
generate_proto() {
    local proto_file="$1"
    local args=""
    args="-I protos"
    if [ -n "$PROTO_INC" ]; then
        args="$args -I $PROTO_INC"
    fi
    args="$args --plugin=protoc-gen-dart=$PROTOC_GEN_DART"
    args="$args --dart_out=grpc:$OUTPUT_DIR"
    args="$args $proto_file"

    protoc $args
}

# Generate from a single proto file or all files
if [ $# -eq 1 ]; then
    # Generate specific file
    TARGET_FILE="$1"
    if [ ! -f "$TARGET_FILE" ]; then
        echo "❌ File not found: $TARGET_FILE"
        exit 1
    fi
    echo "Generating from: $TARGET_FILE"
    generate_proto "$TARGET_FILE"
    echo "✓ Generated: $(basename "$TARGET_FILE")"

    # Also generate well-known types if the file imports them
    if grep -q "google/protobuf/timestamp.proto\|google/protobuf/duration.proto" "$TARGET_FILE"; then
        echo "Generating well-known types..."
        if [ -n "$PROTO_INC" ]; then
            for wkt in timestamp empty duration; do
                wkt_file="$PROTO_INC/google/protobuf/${wkt}.proto"
                if [ -f "$wkt_file" ]; then
                    generate_proto "$wkt_file"
                    echo "✓ Generated: google/protobuf/${wkt}.proto"
                fi
            done
        fi
    fi
else
    # Generate all proto files
    if [ ! -d "$PROTO_DIR" ]; then
        echo "❌ protos/ directory not found"
        exit 1
    fi
    if [ -z "$(ls -A "$PROTO_DIR"/*.proto 2>/dev/null)" ]; then
        echo "❌ No .proto files found in $PROTO_DIR/"
        exit 1
    fi

    # Collect all well-known types needed
    NEEDS_TIMESTAMP=false
    NEEDS_DURATION=false
    NEEDS_EMPTY=false
    for proto_file in "$PROTO_DIR"/*.proto; do
        if grep -q "google/protobuf/timestamp.proto" "$proto_file"; then
            NEEDS_TIMESTAMP=true
        fi
        if grep -q "google/protobuf/duration.proto" "$proto_file"; then
            NEEDS_DURATION=true
        fi
        if grep -q "google/protobuf/empty.proto" "$proto_file"; then
            NEEDS_EMPTY=true
        fi
    done

    for proto_file in "$PROTO_DIR"/*.proto; do
        echo "Generating from: $(basename "$proto_file")"
        generate_proto "$proto_file"
        echo "✓ Generated: $(basename "$proto_file")"
    done

    # Generate well-known types if any proto file needs them
    if [ "$NEEDS_TIMESTAMP" = true ] || [ "$NEEDS_DURATION" = true ] || [ "$NEEDS_EMPTY" = true ]; then
        echo ""
        echo "Generating well-known types..."
        if [ -n "$PROTO_INC" ]; then
            [ "$NEEDS_TIMESTAMP" = true ] && \
                generate_proto "$PROTO_INC/google/protobuf/timestamp.proto" && \
                echo "✓ Generated: google/protobuf/timestamp.proto"
            [ "$NEEDS_DURATION" = true ] && \
                generate_proto "$PROTO_INC/google/protobuf/duration.proto" && \
                echo "✓ Generated: google/protobuf/duration.proto"
            [ "$NEEDS_EMPTY" = true ] && \
                generate_proto "$PROTO_INC/google/protobuf/empty.proto" && \
                echo "✓ Generated: google/protobuf/empty.proto"
        fi
    fi
fi

echo ""
echo "✅ Proto files generated successfully in $OUTPUT_DIR/"
echo ""
echo "To use the generated code with buffer serialization:"
echo "  // Serialize to buffer"
echo "  List<int> bytes = myRequest.writeToBuffer();"
echo "  // Deserialize from buffer"
echo "  MyResponse response = MyResponse.fromBuffer(bytes);"
echo ""
echo "Next steps:"
echo "  1. flutter pub get  # if new dependencies were added"
echo "  2. Commit generated files: git add lib/core/network/generated/"
