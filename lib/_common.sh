#!/bin/bash

# .playground files can change these values
deploymentProcess=kubernetes # other acceptable value: 'rsync'
rsyncIgnore=(node_modules) # '.git' is automatically added
deploymentName='' # kubernetes deployment to restart -- empty means deployment has same name as app

function h1 { 
	(>&2 echo  $'\n\x1b[36;1;4m'$@$'\x1b[0m')
}
function h2 { 
	(>&2 echo  $'\x1b[36m \xe2\x86\xb3 '$@$'\x1b[0m')
}

context='default'
unhandledParameters=()
for i in $@; do
	case $i in
    --app=*)
      app=($(sed -e 's/^--app=//' <<< $i)) 
      ;;
    --context=*)
      context=$(sed -e 's/^--context=//' <<< $i)
      ;;
    -h|--help)
      printHelp
      ;;      
    *)
      unhandledParameters+=(${i})
      ;;
  esac
done

if [ -z "${app}" ] || [ -z "${context}" ]; then 
  printHelp 1
fi

function findConfig {
  displayType=$1
  type=$2
  name=$3
  testFolders=()
  if [ ! -z "${DEPLOY_HOME}" ]; then
    testFolders+=("${DEPLOY_HOME}")
  fi
  testFolders+=("." "~/.deploy" "/etc/deploy" )
  testFoldersSh=()
  for i in ${testFolders[@]}; do
    testFoldersSh+=("${i}/${type}/${name}.sh" "${i}/${type}/${name}")
  done
  for path in ${testFoldersSh[@]}; do
    if [ -e "${path}" ]; then
      echo "${path}"
      return 0
    fi
  done

  echo $displayType $name not found in directories:
  for i in ${testFolders[@]}; do
    echo " - $i/${type}"
  done
  printHelp 1
}
function findContext {
  findConfig "Context" "contexts" $1
}
function findApp {
  findConfig "App" "apps" $1
}

source $(findContext ${context})
source $(findApp ${app})

rsyncExclude=''
for i in .git ${rsyncIgnore[@]}; do
  rsyncExclude+=" --exclude ${i}"
done