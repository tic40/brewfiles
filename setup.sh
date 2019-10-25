#!/bin/bash

# install HomeBrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install applications from Brewfile
brew tap Homebrew/bundle
brew bundle
