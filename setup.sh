#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="${1:-}"

if [[ "$PROFILE" != "private" && "$PROFILE" != "work" ]]; then
  echo "Usage: $0 <private|work>" >&2
  exit 1
fi

HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"

# install Homebrew if not exists
if command -v brew &> /dev/null; then
  echo "Homebrew is already installed"
else
  if [[ ! -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # the installer does not add brew to the PATH of this process
  eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
fi

# install packages from Brewfile
brew bundle install --file="$SCRIPT_DIR/Brewfile.$PROFILE"

# install Claude Code (native installer)
if ! command -v claude &> /dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
