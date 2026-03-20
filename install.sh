#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="${APPSECAI_VERSION:-latest}"
GITHUB_REPO="${GITHUB_REPO:-AppSecureAI/appsecai-cli}"
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="${INSTALL_DIR}/appsecai"
LEGACY_INSTALL_PATH="${INSTALL_DIR}/appsecai-cli"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════╗"
echo "║   AppSecAI CLI Installer          ║"
echo "╚═══════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Platform detection
case "$OS" in
  Darwin)
    OS_TYPE="macos"
    ;;
  Linux)
    OS_TYPE="linux"
    ;;
  *)
    echo -e "${RED}Error: Unsupported OS: $OS${NC}"
    echo "Currently supported: macOS, Linux"
    echo "Windows support coming soon."
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64 | amd64)
    ARCH_TYPE="x64"
    ;;
  arm64 | aarch64)
    ARCH_TYPE="arm64"
    ;;
  *)
    echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
    echo "Supported: x64, arm64"
    exit 1
    ;;
esac

BINARY_NAME="appsecai-${OS_TYPE}-${ARCH_TYPE}"

echo "Detected system: ${OS_TYPE} ${ARCH_TYPE}"
echo ""

# Security: Validate URL uses HTTPS (except localhost for testing)
validate_https() {
  local url="$1"

  # Allow localhost/127.0.0.1 for local testing
  if echo "$url" | grep -qE '^https?://(localhost|127\.0\.0\.1)'; then
    return 0
  fi

  # Require HTTPS for all other URLs
  if ! echo "$url" | grep -qE '^https://'; then
    echo -e "${RED}Error: HTTPS required for security${NC}"
    echo "URL: $url"
    echo "Only HTTPS URLs are allowed (HTTP is insecure)"
    exit 1
  fi
}

# Set download URLs
if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/${BINARY_NAME}"
  CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/checksums.txt"
else
  DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/${BINARY_NAME}"
  CHECKSUM_URL="https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/checksums.txt"
fi

# Validate URLs are secure
validate_https "$DOWNLOAD_URL"
validate_https "$CHECKSUM_URL"

# Check for curl or wget
if command -v curl &> /dev/null; then
  DOWNLOADER="curl"
elif command -v wget &> /dev/null; then
  DOWNLOADER="wget"
else
  echo -e "${RED}Error: curl or wget is required${NC}"
  echo "Install with: brew install curl  (macOS)"
  echo "           or: apt-get install curl  (Linux)"
  exit 1
fi

# Download binary
echo -e "${BLUE}→${NC} Downloading appsecai CLI..."
TMP_FILE="/tmp/appsecai-$$"

if [ "$DOWNLOADER" = "curl" ]; then
  if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
    echo -e "${RED}Error: Download failed${NC}"
    echo "URL: $DOWNLOAD_URL"
    exit 1
  fi
else
  if ! wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"; then
    echo -e "${RED}Error: Download failed${NC}"
    echo "URL: $DOWNLOAD_URL"
    exit 1
  fi
fi

# Verify download
if [ ! -f "$TMP_FILE" ] || [ ! -s "$TMP_FILE" ]; then
  echo -e "${RED}Error: Downloaded file is empty or missing${NC}"
  exit 1
fi

# Check file size (should be reasonable for binary)
FILE_SIZE=$(stat -f%z "$TMP_FILE" 2>/dev/null || stat -c%s "$TMP_FILE" 2>/dev/null || echo 0)
if [ "$FILE_SIZE" -lt 10000000 ]; then  # Less than 10MB seems wrong
  echo -e "${RED}Error: Downloaded file size too small (${FILE_SIZE} bytes)${NC}"
  echo "This might not be a valid binary."
  rm -f "$TMP_FILE"
  exit 1
fi

# Download checksum
echo -e "${BLUE}→${NC} Downloading checksums..."
TMP_CHECKSUM="/tmp/appsecai-checksums-$$"

if [ "$DOWNLOADER" = "curl" ]; then
  curl -fsSL "$CHECKSUM_URL" -o "$TMP_CHECKSUM" 2>/dev/null || true
else
  wget -q "$CHECKSUM_URL" -O "$TMP_CHECKSUM" 2>/dev/null || true
fi

# Validate and set permissions after install
validate_and_set_permissions() {
  local file="$1"
  local expected_perms="755"

  echo -e "${BLUE}→${NC} Setting binary permissions..."

  # Set explicit permissions and ownership
  if command -v sudo &> /dev/null && [ "$(id -u)" != "0" ]; then
    sudo chown root:$([ "$OS_TYPE" = "macos" ] && echo "wheel" || echo "root") "$file" 2>/dev/null || true
    sudo chmod "$expected_perms" "$file"
  else
    chmod "$expected_perms" "$file"
  fi

  # Verify permissions
  local actual_perms
  if [ "$OS_TYPE" = "macos" ]; then
    actual_perms=$(stat -f '%p' "$file" 2>/dev/null | tail -c 4)
  else
    actual_perms=$(stat -c '%a' "$file" 2>/dev/null)
  fi

  actual_perms=${actual_perms#0}

  if [ "$actual_perms" != "$expected_perms" ]; then
    echo -e "${YELLOW}Warning: Binary has unexpected permissions: $actual_perms${NC}"
    echo -e "${YELLOW}Expected: $expected_perms (rwxr-xr-x)${NC}"
    echo ""
    echo "To fix manually:"
    echo "  sudo chmod $expected_perms $file"
    return 1
  fi

  echo -e "${GREEN}✓ Permissions validated: $actual_perms${NC}"
  return 0
}

validate_downloaded_binary() {
  local file="$1"

  echo -e "${BLUE}→${NC} Validating downloaded binary format..."

  if [ ! -f "$file" ] || [ ! -s "$file" ]; then
    echo -e "${RED}Error: Downloaded binary missing during validation${NC}"
    exit 1
  fi

  chmod 755 "$file"

  local file_info
  file_info=$(file "$file" 2>/dev/null || true)

  case "${OS_TYPE}-${ARCH_TYPE}" in
    macos-arm64)
      if ! echo "$file_info" | grep -q "Mach-O"; then
        echo -e "${RED}Error: Downloaded file is not a macOS Mach-O executable${NC}"
        echo "Details: $file_info"
        exit 1
      fi
      if ! echo "$file_info" | grep -Eq "arm64"; then
        echo -e "${RED}Error: Downloaded file architecture mismatch (expected arm64)${NC}"
        echo "Details: $file_info"
        exit 1
      fi
      ;;
    macos-x64)
      if ! echo "$file_info" | grep -q "Mach-O"; then
        echo -e "${RED}Error: Downloaded file is not a macOS Mach-O executable${NC}"
        echo "Details: $file_info"
        exit 1
      fi
      if ! echo "$file_info" | grep -Eq "x86_64"; then
        echo -e "${RED}Error: Downloaded file architecture mismatch (expected x64)${NC}"
        echo "Details: $file_info"
        exit 1
      fi
      ;;
    linux-x64)
      if ! echo "$file_info" | grep -Eq "ELF 64-bit.*x86-64"; then
        echo -e "${RED}Error: Downloaded file is not a Linux x64 ELF executable${NC}"
        echo "Details: $file_info"
        exit 1
      fi
      ;;
  esac

  if [ "$OS_TYPE" = "macos" ]; then
    if ! otool -l "$file" | grep -q "LC_CODE_SIGNATURE"; then
      echo -e "${RED}Error: Downloaded macOS binary is missing LC_CODE_SIGNATURE${NC}"
      echo "This indicates a malformed/tampered artifact and it may be killed at launch."
      exit 1
    fi
    if ! codesign -dv --verbose=2 "$file" >/dev/null 2>&1; then
      echo -e "${RED}Error: Downloaded macOS binary has an invalid/unreadable code signature${NC}"
      echo "This indicates a malformed artifact and it may not execute."
      exit 1
    fi
  fi

  echo -e "${BLUE}→${NC} Running install-time smoke check..."
  local smoke_output
  if ! smoke_output=$("$file" --help 2>&1); then
    echo -e "${RED}Error: Downloaded binary failed smoke check (--help)${NC}"
    echo "Output:"
    echo "$smoke_output"
    exit 1
  fi

  echo -e "${GREEN}✓ Binary validation passed${NC}"
}

atomic_verify_and_install() {
  local tmp_file="$1"
  local install_path="$2"
  local checksum_file="$3"
  local binary_name="$4"

  echo -e "${BLUE}→${NC} Verifying checksum..."

  if [ -f "$checksum_file" ] && [ -s "$checksum_file" ]; then
    local expected_checksum
    expected_checksum=$(grep "${binary_name}" "$checksum_file" 2>/dev/null | awk '{print $1}')

    if [ -n "$expected_checksum" ]; then
      local actual_checksum
      if command -v shasum &> /dev/null; then
        actual_checksum=$(shasum -a 256 "$tmp_file" | awk '{print $1}')
      elif command -v sha256sum &> /dev/null; then
        actual_checksum=$(sha256sum "$tmp_file" | awk '{print $1}')
      else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠ SECURITY WARNING ⚠${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}sha256sum/shasum not found - cannot verify checksums${NC}"
        echo -e "${YELLOW}Install shasum (macOS) or sha256sum (Linux) for security${NC}"
        echo -e "${YELLOW}Proceeding anyway (use at your own risk)${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        actual_checksum=""
      fi

      if [ -n "$actual_checksum" ]; then
        if [ "$expected_checksum" = "$actual_checksum" ]; then
          echo -e "${GREEN}  ✓ Checksum verified${NC}"
        else
          echo -e "${RED}Error: Checksum verification failed${NC}"
          echo "Expected: $expected_checksum"
          echo "Actual:   $actual_checksum"
          rm -f "$tmp_file" "$checksum_file"
          exit 1
        fi
      fi
    fi
    rm -f "$checksum_file"
  else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠ SECURITY WARNING ⚠${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Checksums not available - cannot verify binary integrity${NC}"
    echo -e "${YELLOW}This may indicate a network issue or incomplete release${NC}"
    echo -e "${YELLOW}Proceeding anyway (use at your own risk)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
  fi

  echo -e "${BLUE}→${NC} Installing to ${INSTALL_DIR}..."

  if [ -w "$INSTALL_DIR" ]; then
    mv "$tmp_file" "$install_path" && chmod 755 "$install_path"
    ln -sf "$install_path" "$LEGACY_INSTALL_PATH"
  else
    echo -e "${YELLOW}  Requesting sudo access to install to ${INSTALL_DIR}${NC}"
    local sudo_script="/tmp/appsecai-install-$$.sh"
    cat > "$sudo_script" <<'SUDO_EOF'
#!/bin/bash
set -e
mv "$1" "$2"
chmod 755 "$2"
ln -sf "$2" "$3"
SUDO_EOF
    chmod +x "$sudo_script"
    if sudo bash "$sudo_script" "$tmp_file" "$install_path" "$LEGACY_INSTALL_PATH"; then
      echo -e "${GREEN}  ✓ Installed successfully${NC}"
    else
      echo -e "${RED}Error: Installation failed${NC}"
      rm -f "$tmp_file"
      rm -f "$sudo_script"
      exit 1
    fi
    rm -f "$sudo_script"
  fi
}

validate_downloaded_binary "$TMP_FILE"
atomic_verify_and_install "$TMP_FILE" "$INSTALL_PATH" "$TMP_CHECKSUM" "$BINARY_NAME"

# Validate permissions immediately after install
validate_and_set_permissions "$INSTALL_PATH"

# Remove quarantine attribute on macOS (prevents Gatekeeper warning)
if [ "$OS_TYPE" = "macos" ]; then
  xattr -d com.apple.quarantine "$INSTALL_PATH" 2>/dev/null || true
fi

# Verify installation
if [ -x "$INSTALL_PATH" ]; then
  VERSION_OUTPUT=$("$INSTALL_PATH" --version 2>&1 || echo "unknown")

  echo ""
  echo -e "${GREEN}╔═══════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ✓ Installation successful!      ║${NC}"
  echo -e "${GREEN}╚═══════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BLUE}Version:${NC} ${VERSION_OUTPUT}"
  echo ""
  echo -e "${BLUE}Get started:${NC}"
  echo "  appsecai login"
  echo "  appsecai submit <file> -r owner/repo -b main"
  echo ""
  echo -e "${BLUE}Documentation:${NC} https://docs.appsecai.io"
  echo -e "${BLUE}Support:${NC} support@appsecai.io"
  echo ""
else
  echo -e "${RED}Error: Installation failed - binary not executable${NC}"
  exit 1
fi
