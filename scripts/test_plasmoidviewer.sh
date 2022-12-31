#!/bin/bash

cd "${0%/*}"

QT_LOGGING_RULES="qml.debug=true" plasmoidviewer -a ../package/
