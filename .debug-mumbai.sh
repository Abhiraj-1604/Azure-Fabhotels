#set the subscription 
export ARM_SUBSCRIPTION_ID="2a1fc2e7-271e-4c68-b79d-603e28cf77aa"

# set the project name 


# set backend config
export BACKEND_CONFIG_RESOURCE_GROUP_NAME="rg-mumbai-tfstate"
export BACKEND_CONFIG_STORAGE_ACCOUNT_NAME="stmumbaitfstatedev"
export BACKEND_CONFIG_CONTAINER_NAME="tfstate-container"        
export BACKEND_CONFIG_KEY="Fab.terraform.tfstate"  

# run terraform 

terraform init \
    -backend-config="resource_group_name=$BACKEND_CONFIG_RESOURCE_GROUP_NAME" \
    -backend-config="storage_account_name=$BACKEND_CONFIG_STORAGE_ACCOUNT_NAME" \
    -backend-config="container_name=$BACKEND_CONFIG_CONTAINER_NAME" \
    -backend-config="key=$BACKEND_CONFIG_KEY"

terraform $* --var-file="env/network.auto.tfvars"

rm -rf .terraform/ .terraform.lock.hcl