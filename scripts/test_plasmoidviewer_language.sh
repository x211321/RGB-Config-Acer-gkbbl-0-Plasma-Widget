#!/bin/bash

cd "${0%/*}"

LANGUAGE="de_DE;de" LAND="de_DE.UTF-8" QT_LOGGING_RULES="qml.debug=true" plasmoidviewer -a ../package/
