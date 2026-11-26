#!/bin/bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROFILE="${1:-}"

if [[ "$PROFILE" != "private" && "$PROFILE" != "work" ]]; then
  echo "Usage: $0 <private|work>" >&2
  exit 1
fi

BREWFILE="$SCRIPT_DIR/Brewfile.$PROFILE"

step() { printf '\n==> %s\n' "$1"; }

step "Updating Homebrew"
brew update

step "Outdated packages"
outdated="$(brew outdated --verbose)"
echo "$outdated"

step "Upgrading packages"
brew upgrade --yes

# The old IME process keeps running after upgrade; macOS relaunches the new one on next input
if grep -qE '^google-japanese-ime( |$)' <<< "$outdated"; then
  step "Restarting Google Japanese IME"
  killall GoogleJapaneseInput GoogleJapaneseInputConverter GoogleJapaneseInputRenderer || true
fi

step "Removing unused dependencies"
brew autoremove

step "Cleaning up old versions and cache"
brew cleanup

step "Checking Brewfile.$PROFILE"
if ! brew bundle check --file="$BREWFILE"; then
  echo "Run: brew bundle install --file=$BREWFILE"
fi

step "Packages not in Brewfile.$PROFILE"
if ! brew bundle cleanup --file="$BREWFILE"; then
  echo "Run: brew bundle cleanup --force --file=$BREWFILE"
fi
