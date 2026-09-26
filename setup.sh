#!/bin/bash
set -e

source .env
echo "Initializing setup process..."

echo -n "Creating resource group $GROUP_NAME..."

#create a resource group
az group create --name $GROUP_NAME \
    --location $REGION

echo "DONE!"

echo -n "Creating storage account $STORAGE_ACCOUNT_NAME..."

#create an azure data lake storage v2 account
az storage account create --name $STORAGE_ACCOUNT_NAME \
    --resource-group $GROUP_NAME \
    --access-tier Hot \
    --enable-hierarchical-namespace true \
    --kind StorageV2 \
    --sku Standard_LRS \
    --location $REGION

echo "DONE!"

echo -n "Creating storage container $CONTAINER_NAME..."

#create a storage container
az storage container create --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --auth-mode "login"

echo "DONE!"

echo -n "Creating databricks workspace $WORKSPACE_NAME..."

#create a databricks workspace
az databricks workspace create \
    --resource-group $GROUP_NAME \
    --name $WORKSPACE_NAME \
    --location $REGION \
    --sku "premium"

echo "DONE!"

echo -n "Obtaining storage key for use..."

AZURE_STORAGE_KEY=$(az storage account keys list \
                    --resource-group $GROUP_NAME \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --query "[0].value" -o tsv)

echo "DONE!"

echo -n "Creating access connector $CONNECTOR_NAME..."

#create an access connector with managed identity
az databricks access-connector create --name $CONNECTOR_NAME \
    --resource-group $GROUP_NAME \
    --location $REGION \
    --identity-type SystemAssigned

echo "DONE!"

echo -n "Attaining Connector ID..."

#attain the object id of the newly created access connector
CONNECTOR_ID=$(az databricks access-connector show \
  --name $CONNECTOR_NAME \
  --resource-group $GROUP_NAME \
  --query "identity.principalId" \
  --output tsv)

echo "DONE!"

echo -n "Assigning 'Storage Blob Data Contributor' to Object ID: $CONNECTOR_ID..."

#get the subscription id
SUBSCRIPTION_ID=$(az account show --query "id" --output tsv)

#define storage scope - the commented out line assigns this to a specific container, but we want to do the whole storage account
# SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME/blobServices/default/containers/$CONTAINER_NAME"
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
SUBSCRIPTION_SCOPE="/subscriptions/$SUBSCRIPTION_ID"

echo "Granting storage blob data contributor role to access connector $CONNECTOR_ID"
echo -n "With scope $SCOPE..."

#grant storage blob data contributor role to access connector
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee-object-id $CONNECTOR_ID \
  --role "Storage Blob Data Contributor" \
  --scope $SCOPE

MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee-object-id $CONNECTOR_ID \
  --role "Storage Account Contributor" \
  --scope $SCOPE

MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee-object-id $CONNECTOR_ID \
  --role "Storage Queue Data Contributor" \
  --scope $SCOPE

MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee-object-id $CONNECTOR_ID \
  --role "EventGrid EventSubscription Contributor" \
  --scope $SUBSCRIPTION_SCOPE

echo "DONE!"

echo -n "Creating bronze directory..."

#create medallion architecture directories
az storage fs directory create --file-system $CONTAINER_NAME \
                               --name $DIRECTORY \
                               --account-name $STORAGE_ACCOUNT_NAME
                               #--auth-mode "login"

echo "DONE!"

echo -n "Creating silver directory..."

az storage fs directory create --file-system $CONTAINER_NAME \
                               --name "silver" \
                               --account-name $STORAGE_ACCOUNT_NAME
                               #--auth-mode "login"

echo "DONE!"
echo -n "Creating gold directory..."

az storage fs directory create --file-system $CONTAINER_NAME \
                               --name "gold" \
                               --account-name $STORAGE_ACCOUNT_NAME
                               #--auth-mode "login"                            

echo "DONE!"
echo -n "Registering EventGrid with subscription..."

az provider register --namespace Microsoft.EventGrid --subscription $SUBSCRIPTION_ID

# ATTENTION - below this line is things I wanted to add but could not
# These things are outside of Azure so it is more difficult

#upload files to container

#echo -n "Uploading file 1/4 to $CONTAINER_NAME/$DIRECTORY..."

#az storage fs file upload --file-system $CONTAINER_NAME \
#    --source "extended_steam_games.csv" \
#    --path "$DIRECTORY/games_muhammadaqeelkabir.csv" \
#    --account-name $STORAGE_ACCOUNT_NAME
    #--auth-mode "key"

#echo "DONE!"
#echo -n "Uploading file 2/4 to $CONTAINER_NAME/$DIRECTORY..."

#az storage fs file upload --file-system $CONTAINER_NAME \
#    --source "games.csv" \
#    --path "$DIRECTORY/games_fronkongames.csv" \
#    --account-name $STORAGE_ACCOUNT_NAME
#    #--auth-mode "key"

#echo "DONE!"
#echo -n "Uploading file 3/4 to $CONTAINER_NAME/$DIRECTORY..."

#az storage fs file upload --file-system $CONTAINER_NAME \
#    --source "games.json" \
#    --path "$DIRECTORY/games_fronkongames.json" \
#    --account-name $STORAGE_ACCOUNT_NAME
    #--auth-mode "key"

#echo "DONE!"
#echo -n "Uploading file 4/4 to $CONTAINER_NAME/$DIRECTORY..."

#az storage fs file upload --file-system $CONTAINER_NAME \
#    --source "weighted_score_above_08.csv" \
#    --path "$DIRECTORY/reviews.json" \
#    --account-name $STORAGE_ACCOUNT_NAME
    #--auth-mode "key"

#echo "DONE!"

#create storage credential

#create external location