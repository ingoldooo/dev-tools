#!/bin/bash

FrontendPackage() {
  extends class NodePackage

  _deploy() {
    [[ ! "$(array_contains "${folderName}" "${ts_deploy[@]}")" ]] && return

    logInfo "Deploying: ${folderName}"
    ${CONST_Firebase} deploy --only hosting
    throwWarning "Error while deploying hosting"
    logInfo "Deployed: ${folderName}"
  }

  _setEnvironment() {
    #    TODO: iterate on all source folders
    logDebug "Setting ${folderName} env: ${envType}"
    copyConfigFile "./.config/config-ENV_TYPE.ts" "./src/main/config.ts" "${envType}" "${fallbackEnv}"
  }

  _compile() {
    logInfo "Compiling: ${folderName}"

    npm run build
    throwWarning "Error compiling: ${folderName}"
  }

  _lint() {
    logInfo "Linting: ${folderName}"

    npm run lint
    throwWarning "Error linting: ${folderName}"
  }

  _launch() {
    [[ ! "$(array_contains "${folderName}" "${ts_launch[@]}")" ]] && return

    logInfo "Launching: ${folderName}"
    npm run launch
  }

  _install() {
    if [[ ! -e "./.config/ssl/server-key.pem" ]]; then
      createDir "./.config/ssl"
      bash ../dev-tools/scripts/utils/generate-ssl-cert.sh --output=./.config/ssl
    fi

    this.NodePackage.install ${@}
  }

  _generate() {
    [[ ! "$(array_contains "${folderName}" "${ts_generate[@]}")" ]] && return

    logInfo "Generating: ${folderName}"
    this.generateSVG
    this.generateFonts
  }

  _generateSVG() {
    local _pwd=$(pwd)

    _pushd "src/main/res/images"
    local files=($(ls | grep .*\.svg))

    local declaration=""
    local usage=""
    for file in "${files[@]}"; do
      local width=$(cat "${file}" | grep -E ' width="[0-9]+"' | sed -E 's/^.* width="([0-9]+)(px)?".*$/\1/')
      local height=$(cat "${file}" | grep -E ' height="[0-9]+"' | sed -E 's/^.* height="([0-9]+)(px)?".*$/\1/')
      local varName=$(echo "${file}" | sed -E 's/icon__(.*).svg/\1/')
      declaration="${declaration}\\nconst ${varName}: IconData = {ratio: ${height} / ${width},  value: require('@res/images/${file}')};"
      usage="${usage}\\n\t${varName}: (color?: string, width?: number) => iconsRenderer(${varName}, color, width),"
    done

    deleteFile ../icons.tsx
    copyFileToFolder "${_pwd}"/../dev-tools/scripts/dev/typescript-oo/templates/icons.tsx ../
    file_replaceLine "ICONS_DECLARATION" "${declaration}" ../icons.tsx
    file_replaceLine "ICONS_USAGE" "${usage}" ../icons.tsx
    _popd
  }

  _generateFonts() {
    local _pwd=$(pwd)
    _pushd "src/main/res/fonts"
    local files=($(ls | grep .*\.ttf))

    local globals=""
    local declaration=""
    local usage=""
    local varName=""
    for file in "${files[@]}"; do
      varName="${file/-/_}"
      varName="${varName,,}"
      varName=$(echo "${varName}" | sed -E 's/(.*).ttf/\1/')

      declaration="${declaration}\\nconst ${varName} = require('@res/fonts/${file}');"
      globals="${globals}\\n@font-face { font-family: ${varName}; src: url(\${${varName}}) }"
      usage="${usage}\\n\t${varName}: (text: string, color?: string, size?: number) => fontRenderer(text, '${varName}', color, size),"
    done

    deleteFile ../fonts.tsx
    copyFileToFolder "${_pwd}"/../dev-tools/scripts/dev/typescript-oo/templates/fonts.tsx ../
    file_replaceLine "FONTS_DECLARATION" "${declaration}" ../fonts.tsx
    file_replaceLine "FONTS_GLOBAL" "${globals}" ../fonts.tsx
    file_replaceLine "FONTS_USAGE" "${usage}" ../fonts.tsx

    _popd
  }
}
