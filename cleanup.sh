#!/bin/bash

source .env

echo -n "Deleting any existing resources..."

az group delete --name $GROUP_NAME --yes

echo "DONE!"