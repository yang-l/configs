#!/usr/bin/env bash

set -x

CSHARP_EXT_VER=$(/usr/bin/code --list-extensions --show-versions | grep ms-vscode.csharp | sed "s|^ms-vscode.csharp@\(.*\)$|\1|")

for RUN_DEP in 4 7 10 `# for .debugger/ .omnisharp/ .razor/`
do
    DEP_URL=$(curl -s https://raw.githubusercontent.com/OmniSharp/omnisharp-vscode/v"${CSHARP_EXT_VER}"/package.json | python -c 'import sys, json; print json.load(sys.stdin)["runtimeDependencies"]['${RUN_DEP}']["url"]')
    DEP_INST_PATH=$(curl -s https://raw.githubusercontent.com/OmniSharp/omnisharp-vscode/v"${CSHARP_EXT_VER}"/package.json | python -c 'import sys, json; print json.load(sys.stdin)["runtimeDependencies"]['${RUN_DEP}']["installPath"]')
    mkdir -p /home/vscode/.vscode/extensions/ms-vscode.csharp-"$CSHARP_EXT_VER"/"$DEP_INST_PATH"

    # download and install
    curl -L -q "$DEP_URL" -o output.zip
    unzip -d /home/vscode/.vscode/extensions/ms-vscode.csharp-"$CSHARP_EXT_VER"/"$DEP_INST_PATH"/ output.zip
    rm output.zip

    # set to executable
    for EXT_BIN in $(curl -s https://raw.githubusercontent.com/OmniSharp/omnisharp-vscode/v"${CSHARP_EXT_VER}"/package.json | python -c 'import sys, json; print " ".join(json.load(sys.stdin)["runtimeDependencies"]['${RUN_DEP}']["binaries"])')
    do
        if [ -f /home/vscode/.vscode/extensions/ms-vscode.csharp-"$CSHARP_EXT_VER"/"$DEP_INST_PATH"/"$EXT_BIN" ]; then
            chmod 0755 /home/vscode/.vscode/extensions/ms-vscode.csharp-"$CSHARP_EXT_VER"/"$DEP_INST_PATH"/"$EXT_BIN"
        fi
    done
done

# mark all dependencies are installed
touch /home/vscode/.vscode/extensions/ms-vscode.csharp-"$CSHARP_EXT_VER"/install.Lock
