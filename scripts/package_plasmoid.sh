 #!/bin/bash

cd "${0%/*}"
cd ..

version=$(awk -F "=" '/X-KDE-PluginInfo-Version/ {print $2}' ./package/metadata.desktop)

zip -r ./scripts/RGB-Config-Acer_$version.plasmoid ./package

cd "${0%/*}"

