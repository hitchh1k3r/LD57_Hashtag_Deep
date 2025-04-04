#!/bin/bash

echo "Building..." &&
 odin build src -out:artifacts/web/ld57.wasm -target:js_wasm32 &&
 echo "Complete" &&
 xdotool search --onlyvisible --class "Brave-browser" windowactivate --sync key F5
