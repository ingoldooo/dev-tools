#!/bin/bash

debug=
mergeOriginRepo=
cloneNuArt=
pushNuArtMessage=

dirtyLib=
cleanDirt=

purge=
clean=

setup=
install=true
listen=
linkDependencies=true
test=
build=true
lint=

launchBackend=
launchFrontend=

envType=
deployBackend=
deployFrontend=

promoteNuArtVersion=
promoteAppVersion=
publish=
newAppVersion=
thunderstorm=

modulesPackageName=()
modulesVersion=()

params=(thunderstorm mergeOriginRepo cloneNuArt pushNuArtMessage purge clean setup newVersion linkDependencies install build lint cleanDirt test launchBackend launchFrontend envType promoteNuArtVersion promoteAppVersion deployBackend deployFrontend version publish)

function extractParams() {
    for paramValue in "${@}"; do
        case "${paramValue}" in
            "--help")
                printHelp
            ;;

            "--debug")
                debug=true
            ;;

            "--merge-origin")
                mergeOriginRepo=true
            ;;

            "--thunderstorm")
                thunderstorm=true
            ;;

            "--unthunderstorm")
                thunderstorm=false
            ;;

            "--nu-art")
                cloneNuArt=true
            ;;

            "--push="*)
                pushNuArtMessage=`echo "${paramValue}" | sed -E "s/--push=(.*)/\1/"`
            ;;

#        ==== CLEAN =====
            "--purge")
                purge=true
                clean=true
            ;;

            "--clean")
                clean=true
            ;;


#        ==== BUILD =====
            "--setup" | "-s")
                setup=true
                linkDependencies=true
            ;;

            "--unlink" | "-u")
                setup=true
            ;;

            "--link-only" | "-lo")
                linkDependencies=true
                build=
            ;;

            "--clean-dirt")
                cleanDirt=true
                clean=true
            ;;

            "--flag-dirty="*)
                dirtyLib=`echo "${paramValue}" | sed -E "s/--flag-dirty=(.*)/\1/"`
            ;;

            "--no-build" | "-nb")
                build=
            ;;

            "--lint")
                lint=true
            ;;

            "--test" | "-t")
                test=true
            ;;

            "--listen" | "-l")
                listen=true
                build=
            ;;


#        ==== DEPLOY =====
            "--deploy" | "-d")
                deployBackend=true
                deployFrontend=true
                lint=true
            ;;

            "--deploy-backend" | "-db")
                deployBackend=true
                lint=true
            ;;

            "--deploy-frontend" | "-df")
                deployFrontend=true
                lint=true
            ;;

            "--quick-deploy" | "-qd")
                lint=
                build=
                install=
                linkDependencies=
            ;;

            "--set-env="* | "-se="*)
                envType=`echo "${paramValue}" | sed -E "s/(--set-env=|-se=)(.*)/\2/"`
            ;;

            "--set-version="* | "-sv="*)
                newAppVersion=`echo "${paramValue}" | sed -E "s/(--set-version=|-sv=)(.*)/\2/"`
                linkDependencies=true
                build=true
                lint=true
            ;;

#        ==== LAUNCH =====
            "--launch" | "-la")
                envType=dev
                launchBackend=true
                launchFrontend=true
            ;;

            "--launch-backend" | "-lb")
                envType=dev
                launchBackend=true
            ;;

            "--launch-frontend" | "-lf")
                launchFrontend=true
            ;;

#        ==== PUBLISH =====
            "--publish" | "-p")
                clean=true
                build=true
                publish=true
                lint=true
            ;;

            "--version-nu-art="* | "-vn="*)
                promoteNuArtVersion=`echo "${paramValue}" | sed -E "s/(--version-nu-art=|-vn=)(.*)/\2/"`
                linkDependencies=true
                build=true
                lint=true
            ;;

#        ==== ERRORS & DEPRECATION =====
            "--get-config-backend"*)
                logWarning "COMMAND IS DEPRECATED... USE --get-backend-config"
            ;;

            "-gcb")
                logWarning "COMMAND IS DEPRECATED... USE -gbc"
            ;;

            "--set-config-backend"*)
                logWarning "COMMAND IS DEPRECATED... USE --set-backend-config"
            ;;

            "-scb"*)
                logWarning "COMMAND IS DEPRECATED... USE -sbc"
            ;;

            *)
                logWarning "UNKNOWN PARAM: ${paramValue}";
            ;;
        esac
    done
}
