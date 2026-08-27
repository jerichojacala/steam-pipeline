#!/bin/bash

REGION="centralus"
GROUP_NAME="jjacalasteam"
STORAGE_ACCOUNT_NAME="steamstorage"
WORKSPACE_NAME="steamdatabricks"
CONTAINER_NAME="steamcontainer"
CONNECTOR_NAME="steamconnector"

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
az storage container create --name $CONTAINER_NAME \
    --resource-group $GROUP_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --location $REGION

#create a databricks workspace
az databricks workspace create \
    --resource-group $GROUP_NAME \
    --name $WORKSPACE_NAME \
    --location $REGION

#create an access connector with managed identity
az databricks access-connector create --name $CONNECTOR_NAME \
    --resource-group $GROUP_NAME \
    --location $REGION

#attain the object id of the newly created access connector
CONNECTOR_ID=$(az databricks access-connector show \
  --name $CONNECTOR_NAME \
  --resource-group $GROUP_NAME \
  --query "identity.principalId" \
  --output tsv)

echo "Assigning 'Storage Blob Data Contributor' to Object ID: $CONNECTOR_ID..."

#get the subscription id
SUBSCRIPTION_ID=$(az account show --query "id" --output tsv)

#define storage scope
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$CONTAINER_NAME"

#grant storage blob data contributor role to access connector
az role assignment create \
  --assignee $CONNECTOR_ID \
  --role "Storage Blob Data Contributor" \
  --scope $SCOPE

#create storage credential

#create external location