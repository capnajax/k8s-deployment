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
lastUpdatePod=''

function getLastUpdateId {
	local setBaseline=$([ -z "${1}" ] && echo false || echo $1)
	local updateKey=$(kubectl get pods --selector=${podSelector} -o jsonpath="{.items[?(.status.phase=='Running')]['status.phase', 'metadata.name']}")
	if [ -z "${updateKey}" ]; then
		# means there is not pod with this selector
		updateKey="no_pod"
		if $setBaseline; then
			lastUpdateId=${updateKey}
			echo "Previous update unknown, ${appName} not running"
		fi
	else
		if $setBaseline; then
			echo "Previous update: ${updateKey}"
			lastUpdateId=${updateKey}
		fi
	fi
	if $setBaseline || [ "${lastUpdateId}" == "${updateKey}" ]; then
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
	else
		echo -n Restarting deployment...
	fi
elif [ "${deploymentProcess}" == "rsync" ]; then
	deployToRsync
	echo -n Deployment complete
else
	echo WARNING: unknown deploymentProcess
fi

# await the lastUpdateId to change
if [ ! -z "${appDeployment}" ] && [ ! -z "${updateTestId}" ]; then
	while getLastUpdateId; do
		sleep 1
		echo -n .
	done
	echo done.
fi
kubectl get pods --selector=${podSelector}
