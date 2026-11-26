#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="${1:-}"

if [[ "$PROFILE" != "private" && "$PROFILE" != "work" ]]; then
  echo "Usage: $0 <private|work>" >&2
  exit 1
fi

# install Homebrew if not exists
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed"
fi

# install packages from Brewfile
brew bundle install --file="$SCRIPT_DIR/Brewfile.$PROFILE"

# install Claude Code (native installer)
if ! command -v claude &> /dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi
