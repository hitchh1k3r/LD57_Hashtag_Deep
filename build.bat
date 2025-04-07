@echo Building...&& ^
odin build src -out:artifacts/web/ld57.wasm -o:speed -target:js_wasm32 && ^
echo Complete&& ^
refresh_brave.ahk
