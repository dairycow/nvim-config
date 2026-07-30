#!/usr/bin/env bash
# Reproducible Neovim setup installer.
# Installs system deps (auto-detecting package manager), copies init.lua,
# bootstraps all plugins, and compiles Treesitter parsers.
#
# Requirements for nvim-treesitter (main branch): Neovim 0.12+, tree-sitter CLI,
# a C compiler, curl, tar. See https://github.com/nvim-treesitter/nvim-treesitter
set -euo pipefail

NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=12

echo "==> Neovim config installer"

# ---------------------------------------------------------------------------
# 1. Detect package manager and install system dependencies
# ---------------------------------------------------------------------------
install_pkgs() {
  if command -v pacman >/dev/null 2>&1; then
    echo "==> Detected pacman (Arch). Installing deps..."
    sudo pacman -S --needed --noconfirm neovim tree-sitter-cli ripgrep gcc make git curl tar
  elif command -v apt-get >/dev/null 2>&1; then
    echo "==> Detected apt (Debian/Ubuntu). Installing deps..."
    # Debian 'neovim' may be old; see README if Treesitter parser install fails.
    sudo apt-get update
    sudo apt-get install -y neovim ripgrep build-essential git curl tar
    # tree-sitter CLI is not in older Debian repos; install via cargo if available
    if ! command -v tree-sitter >/dev/null 2>&1; then
      echo "==> tree-sitter CLI missing; installing via cargo..."
      command -v cargo >/dev/null 2>&1 || sudo apt-get install -y cargo
      cargo install tree-sitter-cli
    fi
  elif command -v dnf >/dev/null 2>&1; then
    echo "==> Detected dnf (Fedora). Installing deps..."
    sudo dnf install -y neovim tree-sitter-cli ripgrep gcc make git curl tar
  elif command -v brew >/dev/null 2>&1; then
    echo "==> Detected Homebrew (macOS). Installing deps..."
    brew install neovim tree-sitter ripgrep make git curl tar
  else
    echo "ERROR: No supported package manager found (pacman/apt/dnf/brew)." >&2
    echo "Install manually: neovim(>=0.12) tree-sitter-cli ripgrep gcc make git curl tar" >&2
    exit 1
  fi
}

install_pkgs

# ---------------------------------------------------------------------------
# 2. Verify Neovim version (needs >= 0.12 for nvim-treesitter main branch)
# ---------------------------------------------------------------------------
if ! command -v nvim >/dev/null 2>&1; then
  echo "ERROR: neovim not found after install." >&2
  exit 1
fi
nvim_version="$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
nvim_major="${nvim_version%%.*}"
nvim_rest="${nvim_version#*.}"
nvim_minor="${nvim_rest%%.*}"
echo "==> Neovim version: ${nvim_version}"
if [ "${nvim_major}" -lt "${NVIM_MIN_MAJOR}" ] \
   || { [ "${nvim_major}" -eq "${NVIM_MIN_MAJOR}" ] && [ "${nvim_minor}" -lt "${NVIM_MIN_MINOR}" ]; }; then
  echo "ERROR: Neovim >= ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} required (got ${nvim_version})." >&2
  echo "Use an AppImage/nightly: https://github.com/neovim/neovim/releases" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Copy init.lua into place
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/init.lua"
DEST_DIR="${HOME}/.config/nvim"
DEST="${DEST_DIR}/init.lua"

mkdir -p "${DEST_DIR}"
if [ ! -f "${SRC}" ]; then
  echo "ERROR: init.lua not found next to this script (${SRC})." >&2
  exit 1
fi
cp "${SRC}" "${DEST}"
echo "==> Installed config: ${DEST}"

# ---------------------------------------------------------------------------
# 4. Bootstrap plugins (lazy.nvim) + compile Treesitter parsers
# ---------------------------------------------------------------------------
echo "==> Bootstrapping plugins and Treesitter parsers (this takes a minute)..."
nvim --headless "+Lazy! sync" +qa
nvim --headless \
  -c "lua require('nvim-treesitter').install({ 'rust', 'lua', 'vim', 'vimdoc', 'query' }):wait(300000)" \
  -c "qa"

# ---------------------------------------------------------------------------
# 5. Verify
# ---------------------------------------------------------------------------
theme="$(nvim --headless -c "lua print(vim.g.colors_name or 'NONE')" -c "qa" 2>/dev/null | tail -1 | tr -d '\r')"
echo "==> Active colorscheme: ${theme}"
if [ "${theme}" = "ayu" ]; then
  echo "==> SUCCESS. Run 'nvim' to start."
else
  echo "WARNING: expected 'ayu' theme, got '${theme}'. Open nvim and run :Lazy sync." >&2
fi
