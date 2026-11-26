# brewfiles

Brewfile management for macOS setup.

## Structure

- `Brewfile.common` - packages for all machines
- `Brewfile.private` - private machine (includes common)
- `Brewfile.work` - work machine (includes common)

## Prerequisites

- macOS
- Xcode Command Line Tools (`xcode-select --install`)

## Install

```bash
git clone https://github.com/tic40/brewfiles.git
cd brewfiles
./setup.sh private  # or: ./setup.sh work
```

## Update

Edit the Brewfiles manually (`brew bundle dump` would overwrite the split structure).

```bash
PROFILE=private  # or work

# Install from Brewfile
brew bundle install --file=Brewfile.$PROFILE

# Check what would be removed (packages not in Brewfile)
brew bundle cleanup --file=Brewfile.$PROFILE

# Remove packages not in Brewfile
brew bundle cleanup --force --file=Brewfile.$PROFILE
```
