#!/bin/bash

# homebrew
if ! which brew > /dev/null; then
    sudo chown -R "$(whoami)":admin '/usr/local';
    /usr/bin/ruby -e "$(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')";
    mkdir -p '/Library/Caches/Homebrew';
    sudo chown -R "$(whoami)":admin '/Library/Caches/Homebrew';
fi;

# install apps
brew update;
brew bundle;

# install swiftenv
eval "$(curl -sL https://gist.githubusercontent.com/kylef/5c0475ff02b7c7671d2a/raw/9f442512a46d7a2af7b850d65a7e9bd31edfb09b/swiftenv-install.sh)";

vapor fetch;
echo y | vapor xcode;
