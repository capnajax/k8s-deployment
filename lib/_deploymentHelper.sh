#!/bin/bash

NODE_VERSION=v12.10.0
DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

function printHelp {
	echo $'Usage: ./_deploymentHelper.sh [--help|-h] --app=<app> [--context=context] [--switchContext]'
	echo "By default, deploys to all live servers and starts process. Flags to change" 
	echo "behaviours below:"
	echo $'\t--app=<app>  - deploy apps (so far only `id-management` supported)'
	echo $'\t--context=<context>  - deployment context'
	echo $'\t--help | -h  - print this help message and exit'
	echo $'\t--switchContext - switch kube context if context config demands it'
	exit 0
}

source ${DIR}/_common.sh $@

function runDocker {
	echo docker $@
	sudo docker $@
}

lastUpdateId=0

function getLastUpdateId {
	local setBaseline=$([ -z "${1}" ] && echo false || echo $1)
	local updateKey=$($updateTestId)
	if [ $? == 0 ]; then
		if $setBaseline; then
			echo "Previously update: ${updateKey}"
		fi
	else
		updateKey=0
		if $setBaseline; then
			lastUpdateId=${updateKey}
			echo "Previous update unknown, ${appName} not running"
		fi
	fi
	if $setBaseline || [ $lastUpdateId == $epoch ]; then
		return 0
	else
		return 1
	fi
}

function deployToRsync {
	h2 "Transfering ${app} to ${finalHost}"

	cd ${DIR}/../${app}
	echo $(whoami)@$(hostname)
	echo rsync -avz -e ssh --stats --progress --delete ../${app}/* ${rsyncExclude} \
		${finalHost}:${finalDir}
	rsync -avz -e ssh --stats --progress --delete ../${app}/* ${rsyncExclude} \
		${finalHost}:${finalDir}
}

function deployToKubernetes {

	if [ ! -z "${kubeContext}" ]; then
		h2 "Testing kubernetes context"

		if [ "${kubeContext}" != "$(kubectl config current-context)" ]; then
			if ${switchContext}; then
				kubectl config use-context ${kukeContext}
			fi
		fi
	fi

	h2 "Building ${app} image..."

	if $isLocalBuild; then
		cd ${appPath}
	else
		cd ${DIR}/../$(basename $appPath)
	fi
	runDocker build --label=${appLabelPrefix}${appLabel} -t ${app} .

	h2 "Deploying ${app} to Kubernetes"

	runDocker image tag ${app} ${imageTagBase}/${appLabelPrefix}${appLabel}
	runDocker push ${imageTagBase}/${appLabelPrefix}${appLabel}
	if [ ! -z "${appDeployment}" ]; then
		kubectl -n ${namespace} rollout restart deployment/${appDeployment}
	fi
}

# Run pre-deployment task, if provided
if [ ! -z "${preDeploy}" ]; then
	h1 "Running pre-deployment task"
	${preDeploy}
fi

if [ ! -z "${updateTestId}" ] ; then 
	getLastUpdateId true
fi
echo ${deploymentProcess}
if [ "${deploymentProcess}" == "kubernetes" ]; then
	deployToKubernetes
	echo DEPLOYMENT COMPLETE
	if [ -z "${appDeployment}" ]; then
		true
	elif [ -z "${updateTestId}" ]; then
		echo Started deployment restart.
	else
		echo Restarting container...
		echo -n Restarting deployment...
	fi
elif [ "${deploymentProcess}" == "rsync" ]; then
	deployToRsync
	echo -n Deployment complete
else
	echo WARNING: unknown deploymentProcess
fi

# await the lastUpdateId to change
if [ ! -z "${appDeployment}" ] && [ ! -z ${updateTestId} ]; then
	while getLastUpdateId; do
		sleep 1
		echo -n .
	done
	echo done.
fi

