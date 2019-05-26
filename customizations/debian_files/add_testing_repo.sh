#!/usr/bin/env bash

rm                                "/etc/apt/preferences.d/testing"
touch                             "/etc/apt/preferences.d/testing"
echo "Package: *"             >>  "/etc/apt/preferences.d/testing"
echo "Pin: release n=testing" >>  "/etc/apt/preferences.d/testing"
echo "Pin-Priority: 100"      >>  "/etc/apt/preferences.d/testing"


rm                                "/etc/apt/preferences.d/stretch"
touch                             "/etc/apt/preferences.d/stretch"
echo "Package: *"             >>  "/etc/apt/preferences.d/stretch"
echo "Pin: release n=stretch" >>  "/etc/apt/preferences.d/stretch"
echo "Pin-Priority: 700"      >>  "/etc/apt/preferences.d/stretch"

rm     "/etc/apt/sources.list.d/testing.list"
touch  "/etc/apt/sources.list.d/testing.list"
echo "deb http://deb.debian.org/debian/ testing main" \
    >> "/etc/apt/sources.list.d/testing.list"
echo "deb http://security.debian.org/ testing/updates main" \
    >> "/etc/apt/sources.list.d/testing.list"

# Fuck you, badly configured GPG debian servers
apt install dirmngr debian-keyring
gpg --recv-keys \
  9D6D8F6BC857C906 AA8E81B4331F7F50 \
  7638D0442B90D010 04EE7237B7D453EC
gpg --export \
  9D6D8F6BC857C906 AA8E81B4331F7F50 \
  7638D0442B90D010 04EE7237B7D453EC \
  | apt-key add

apt update
