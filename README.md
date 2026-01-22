# brewfiles

Brewfile management for macOS setup.

## Prerequisites

- macOS
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/tic40/brewfiles.git
cd brewfiles
./setup.sh
```

## Update

```bash
# Export current packages to Brewfile
brew bundle dump --force --file=Brewfile

# Install from Brewfile
brew bundle install --file=Brewfile

# Remove packages not in Brewfile
brew bundle cleanup --file=Brewfile
```
