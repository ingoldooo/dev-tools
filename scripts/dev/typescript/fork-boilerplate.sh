#!/bin/bash
source ./dev-tools/scripts/git/_core.sh
source ./dev-tools/scripts/ci/typescript/_source.sh

const_BoilerplateProject=thunderstorm-boilerplate
const_BoilerplateLocation=us-central1

repoUrl=git@github.com:nu-art-js/thunderclone.git
localPath=../thunderstorm-forked
withSources=n
allGood=n
firebaseProject=`firebase use | head -1`
firebaseProjectLocation=us-central22

function signatureThunderstorm() {
    clear
    logVerbose "${Gray}             _____ _                     _                    _                                      ${NoColor}"
    logVerbose "${Gray} -------    |_   _| |__  _   _ _ __   __| | ___ _ __      ___| |_ ___  _ __ _ __ ___    ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | '_ \| | | | '_ \ / _\` |/ _ \ '__|____/ __| __/ _ \| '__| '_ \` _ \ ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      | | | | | | |_| | | | | (_| |  __/ | |_____\__ \ || (_) | |  | | | | | |  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------      |_| |_| |_|\__,_|_| |_|\__,_|\___|_|       |___/\__\___/|_|  |_| |_| |_|  ${Gray}   ------- ${NoColor}"
    logVerbose "${Gray} -------                                                                                ${Gray}   ------- ${NoColor}"
    logVerbose
}

function promptUserForInput() {
    local var=${1}
    local message=${2}
    local defaultValue=${3}

    if [[ "${defaultValue}" ]]; then
        logInfo "${message} [OR press enter to use the current value]"
        logInfo "    (current=${defaultValue})"
    else
        logInfo "${message}"
    fi

    read ${var}
    deleteTerminalLine

    if [[ ! "${!var}" ]]; then
        eval "${var}='${defaultValue}'"
    fi
}

function verifyRepoExists() {
    local repoUrl=${1}
    local output=$(git ls-remote ${repoUrl} 2>&1)
    if [[ "${output}" =~ "ERROR: Repository not found" ]]; then
        return 1
    fi

    if [[ "${output}" =~ "fatal:" ]]; then
        return 2
    fi

    return 0
}

function promptForRepoUrl() {
    promptUserForInput repoUrl "Please enter the repo url to fork into:" ${repoUrl}
    verifyRepoExists ${repoUrl}
    local status=$?
    if [[ "${status}" == "2" ]]; then
        repoUrl=
    fi

    if [[ "${status}" != "0" ]]; then
        promptForRepoUrl
    fi
}

function verifyNpmPackageInstalledGlobally() {
    local package=${1}
    local version=${2}

    logDebug "Verifying package installed ${package}@${version}..."
    local output=$(npm list -g ${package} | grep ${package} 2>&1)
    local code=$?

    if [[ "${code}" != "0" ]]; then
        return 1
    fi

    local foundVersion=`echo ${output} | tail -1 | sed -E "s/.*${package}@(.*)/\1/"`
    if [[ "${foundVersion}" != "${version}" ]]; then
        logWarning "Found wrong version '${foundVersion}' of '${package}...'"
        logInfo "Installing required package version: ${package}@${version}"
        npm i -g ${package}@${version}
        return 1
    fi

    return 0
}

function verifyFirebaseProjectIsAccessible() {
    local firebaseProject=${1}

    logDebug "Verifying You are logged in to firebase tools...'"
    firebase login

    logDebug "Verifying access to firebase project: '${firebaseProject}'"
    local output=$(firebase list | grep "${firebaseProject}" 2>&1)
    if [[ "${output}" =~ "Command requires authentication" ]]; then
        logError "    User not logged in"
        return 2
    fi

    if [[ ! "${output}" =~ "${firebaseProject}" ]]; then
        logError "    No access found"
        return 1
    fi

    return 0
}

function promptForFirebaseProject() {
    promptUserForInput firebaseProject "Please enter the Firebase Project you will be using:" ${firebaseProject}
    verifyFirebaseProjectIsAccessible ${firebaseProject}
    local status=$?
    if [[ "${status}" == "2" ]]; then
        logWarning "Please open another terminal and run 'firebase login' and follow the instruction... \nOnce logged in return to this terminal press enter"
        promptForFirebaseProject
    fi

    if [[ "${status}" != "0" ]]; then
        logWarning "Make sure you have access rights to the firebase project called: ${firebaseProject}"
        promptForFirebaseProject
    fi
}

function promptForFirebaseProjectLocationRepo() {
    promptUserForInput projectLocation "Please enter the Firebase Project LOCATION assigned to your project ${firebaseProjectLocation}"
}

function installNpmPackages() {
    verifyNpmPackageInstalledGlobally "typescript" 3.6.3
    verifyNpmPackageInstalledGlobally "tslint" 5.20.0
    verifyNpmPackageInstalledGlobally "firebase-tools" 7.4.0
    verifyNpmPackageInstalledGlobally "nodemon" latest
    verifyNpmPackageInstalledGlobally "sort-package-json" latest
}

#function verifyLocalPathExists() {
#    local localPath=${1}
#    if [[ -d "${localPath}" ]]; then
#        return 0
#    fi
#
#    mkdir ${localPath}
#    return $?
#}

function promptForLocalPathForFork() {
    promptUserForInput localPath "Please enter the path to fork the project to:" ${localPath}
#    verifyLocalPathExists ${localPath}
#    local status=$?
#    if [[ "${status}" != "0" ]]; then
#        logWarning "Could not create folder at: ${localPath}"
#        promptForLocalPathForFork
#    fi
}

function promptForWithOrWithoutSources() {
    yesOrNoQuestion_new withSources "Do you want to fork with the thunderstorm sources: [y/N]" ${withSources}
}

function promptUserForConfirmation() {
    local userInput=""
    userInput="${userInput}\n    Git fork repository url: ${repoUrl}"
    userInput="${userInput}\n    Local folder for project: ${localPath}"
    userInput="${userInput}\n    Your firebase project name: ${firebaseProject}"
    userInput="${userInput}\n    Your firebase project location: ${firebaseProjectLocation}"
    userInput="${userInput}\n    Keep Thunderstorm sources: ${withSources}"

    yesOrNoQuestion_new allGood "Are all these details correct: [y/N]\n${userInput}" ${allGood}

    case "allGood" in
        [n])
            logError "Aborting fork due to incorrect user input!!"
            exit 2
        ;;
    esac

}

function uploadDefaultConfigToFirebase() {
    logInfo "Setting boilerplate example config to your project"
    local backupFile=".fork/${firebaseProject}_backup_`date +%Y-%m-%d--%H-%M-%S`.json"

    logDebug "Using firebase project: ${firebaseProject}"
    firebase use ${firebaseProject}

    logWarning "If your database has content it will be backed up to: ${backupFile}"
    firebase database:get / > ${backupFile}

    logDebug "Setting example config..."
    firebase database:set -y / .stuff/initial-config.json
}

function forkThunderstorm() {
    local forkingOutput=".fork/${firebaseProject}_forking`date +%Y-%m-%d--%H-%M-%S`.json"
    logInfo "Forking Thunderstorm boilerplate into..."
    bash ./dev-tools/scripts/git/git-fork.sh --to=${repoUrl} --output=${localPath} > ${forkingOutput}
    throwError "Error while forking Thunderstorm... logs can be found here: ${forkingOutput}"
}

function cleanUpForkedRepo() {
    deleteFile ./version-nu-art.json
    if [[ "${withSources}" == "n" ]]; then
        deleteFolder ./ts-common
        deleteFolder ./testelot
        deleteFolder ./thunder
        deleteFolder ./storm

        gitCommit "Removed Thunderstorm sources..."
        gitPush
    fi
}

function replaceBoilerplateNamesWithNewForkedNames() {
    renameStringInFiles ./ ${const_BoilerplateProject} "${firebaseProject}"
    renameStringInFiles ./ ${const_BoilerplateLocation} "${firebaseProjectLocation}"
}

function setupForkedProject() {
    local setupOutput=".fork/${firebaseProject}_forking`date +%Y-%m-%d--%H-%M-%S`.json"
    logInfo "Running initial setup of forked repo..."
    bash ./build-and-install.sh -se=dev --setup
    throwError "Error while forking Thunderstorm... logs can be found here: ${forkingOutput}"
}

function launchForkedProject() {
    local setupOutput=".fork/${firebaseProject}_forking`date +%Y-%m-%d--%H-%M-%S`.json"
    logInfo "Launching forked project..."
    bash ./build-and-install.sh -se=dev --setup
    throwError "Error while forking Thunderstorm... logs can be found here: ${forkingOutput}"
}

function sayHello() {
    signatureThunderstorm
    logInfo "Let's fork thunderstorm...."
    logInfo
    sleep 2s

    logWarning "If you are not familiar with Firebase or git... please educate yourself!"
    logWarning "Bellow is a link to a video tutorial on how to fork Thunderstorm:"
    logWarning
    logWarning "   https://future-link-here"
    sleep 5s
}

function start() {
    sayHello

    installNpmPackages
    promptForRepoUrl
    promptForFirebaseProject
    promptForFirebaseProjectLocationRepo
    promptForLocalPathForFork
    promptForWithOrWithoutSources

    promptUserForConfirmation

    forkThunderstorm
    cd ${localPath}
    cleanUpForkedRepo
    replaceBoilerplateNamesWithNewForkedNames
    uploadDefaultConfigToFirebase
    setupForkedProject

#    echo "Your forked repo url: ${repoUrl}"
#    echo "Your Firebase project: ${firebaseProject}"
#    echo "The Firebase project location: ${firebaseProjectLocation}"


}

start