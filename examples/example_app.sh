#!/bin/bash

# Display Name of the app
appTitle=MyApp

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

# Optional command to test for an update. This command should return
# the same id string every time it's run against the same instance of the app,
# but a different id string for each instance of the app.
# updateTestId=
