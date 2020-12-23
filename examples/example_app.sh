#!/bin/bash

# Display Name of the app
appTitle=MyApp

# A selector for the pod
podSelector=app=my-app

# domain-friendly name of the app
appLabel=my-app

# Directory the app is in
appPath=/Users/myid/Development/Projects/MyApp

# Kubernetes deployment to restart when app image is deployed
appDeployment=my-app-deployment

# Optional command to run to test app before deploying it
# preTest=

# Optional command to run before deploying app. For remote builds,
# this only runs if there are changes, unless `--force` is specified
# preDeploy=
