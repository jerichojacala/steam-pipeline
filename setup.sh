#!/bin/bash

REGION="centralus"
GROUP_NAME="jjacalasteam"
STORAGE_ACCOUNT_NAME="steamstorage"
WORKSPACE_NAME="steamdatabricks"

#create a resource group
az group create --name $GROUP_NAME \ 
    --location $REGION

#create an azure data lake storage v2 account
az storage account create --name $STORAGE_ACCOUNT_NAME \
    --resource-group $GROUP_NAME \
    --access-tier Hot \
    --enable-hierarchical-namespace true \
    --kind StorageV2 \
    --sku Standard_LRS \
    --location $REGION

#create a storage container

#create a databricks workspace
az databricks workspace create \
    --resource-group $GROUP_NAME \
    --name $WORKSPACE_NAME \
    --location $REGION \

#create an access connector with managed identity

#grant storage blob data contributor role to access connector

#create storage credential

#create external location