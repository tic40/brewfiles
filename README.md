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

## Maintenance

Run weekly. Upgrades packages, removes unused dependencies and old versions, and reports differences from the Brewfile (nothing outside the Brewfile is removed automatically).

```bash
./maintenance.sh private  # or: ./maintenance.sh work
```

Test: `./test/maintenance_test.sh`

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
