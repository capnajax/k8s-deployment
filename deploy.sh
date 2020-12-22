#!/bin/bash

# Deploys Playground services from local machine. Must have passwordless SSH
# into pa@f.apicww.cloud

DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

set -e

isForceRedeploy=false
passThroughParams=();

function printHelp {
  echo $''
	echo $'Usage: ./deploy.sh [--help|-h] --app=<app> [--context=<name>] [--force] [--switchContext]'
  echo $'   --app=<app>       - app to deploy.'
  echo $'   --context=<tname> - defined config context. If not found, will look for a'
  echo $'                       context named "default".'
  echo $'   --force           - force rebuild, even if no files are updated.'
	echo $'   --help | -h       - print this help message and exit.'
  echo $'   --switchContext   - change the context if the context config demands it.'
  echo $''
  if [ -z "$1" ]; then
    exit $1
  else
	  exit 0
  fi
}

# parses parameters
source lib/_common.sh $@

# these parameters are passed through to the deployment helper
function fallThroughCase {
  # echo fallThroughCase $1
  passThroughParams+=($1)
  # echo passThroughParams ${passThroughParams[@]}
}

for i in ${unhandledParameters[@]}; do
  case $i in
    --force)
      isForceRedeploy=true
      ;;
    *)
      fallThroughCase $i
      ;;
  esac
done

# ensure app and context are passed on to the deployment helper
fallThroughCase --app=${app}
fallThroughCase --context=${context}

# test the APIs before deploying
if [ ! -z "${preTest}" ]; then
  h1 "Pretesting assets"

  pushd `pwd`
  ${preTest}
  popd
fi

if ! ${isLocalBuild}; then
  # rsync and capture the number of files transferred
  h1 "Transferring deployment files"

  h2 "Preparing environment on ${remoteHost}"
  remoteAppDir=$(basename ${appPath})
  ssh ${remoteHost} "for i in deployment ${remoteAppDir}; do mkdir -p ${remoteDir}/\${i}; done"

  h2 "Transferring deployment script"
  xferFile=$(mktemp)
  rsync -avz -e ssh --stats --progress . \
    --exclude ".git" \
    ${remoteHost}:${remoteDir}/deployment

  h2 "Transferring ${app} files"
  rsync -avz -e ssh --stats --progress ../${app} ${rsyncExclude} \
    ${remoteHost}:${remoteAppDir} | tee $xferFile

  xferQty=$(grep 'Number of files transferred:' ${xferFile} | sed )
fi

if ${isLocalBuild}; then
  h1 "Running deployment helper"
  ${DIR}/lib/_deploymentHelper.sh ${passThroughParams[@]}
elif ${isForceRedeploy} || [ 0 != $(cat ${xferFile} | grep 'Number of files transferred:' | sed -e 's/.*: *//') ]; then
	# if any files are updated, redeploy pods
  h1 "Running depoyment helper on remote host ${remoteHost}"
	ssh ${remoteHost} "cd ${remoteDir}/deployment && ./lib/_deploymentHelper.sh ${passThroughParams[@]}"
else
  h2 "No changes"
fi

echo
