#!/bin/bash

# install HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# install applications from Brewfile
brew tap Homebrew/bundle
brew bundle

chsh -s /bin/zsh
