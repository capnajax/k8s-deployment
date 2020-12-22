#!/bin/bash

# The base name for the image tag. This is generally the docker registry
# and port.
imageTagBase=registry.moon:80

# whether or not to build the image on the local machine
#   true - build the image on the local machine
#   false - copy to a remote machine to build the image
isLocalBuild=true

# The kubernetes namespace to deploy the app to
namespace=k8s-namespace

# The folder to use for building
remoteDir=devops/deploy

# The host to build and deploy on. Ignored if isLocalBuild=true 
remoteHost=k8s.moon

# Kubernetes context to use for deployment
# Note this will not switch contexts unless the `--switchContext`
# parameter is provided. If it is not provided, the deployment will fail.
# If not provided, the Kubernetes context will not be verified.
kubeContext=k8s.moon-moon

# prefix to add to image labels for apps deployed to this context
appLabelPrefix=moon.