#!/usr/bin/env bash

systemctl set-default graphical.target
ln -fs  /etc/systemd/system/autologin@.service \
        /etc/systemd/system/getty.target.wants/getty@tty1.service
