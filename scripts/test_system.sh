#!/bin/bash

cd "${0%/*}"

name=$(awk -F "=" '/X-KDE-PluginInfo-Name/ {print $2}' ../package/metadata.desktop)

mkdir ~/.local/share/plasma/plasmoids/$name

cp -r ../package/* ~/.local/share/plasma/plasmoids/$name

nohup plasmashell --replace &
