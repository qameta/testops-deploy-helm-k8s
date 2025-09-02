# TestOps deploy in Kubernetes

Here we give just a recap on how to deploy TestOps in your own Kubernetes cluster using Helm chart maintained by Qameta Software Inc.

## Deploy description

https://docs.qameta.io/allure-testops/install/kubernetes/

## Support

Chart is supported via https://help.qameta.io

## Database

Do not deploy PostgreSQL using this chart. Such deployment is not suitable for production.

Here we collected some recommendations for the database configuration to ensure acceptable performance: https://docs.qameta.io/allure-testops/install/database/

## values.yaml template file

1. Download the values template file from this very repo.

    https://github.com/qameta/testops-deploy-helm-chart/blob/master/charts/testops/values.yaml

2. Update values.yaml file based on you preferences and existing infrastructure elements.
3. Deploy TestOps using Helm commands.

## Helm commands

```bash
helm repo add qameta https://dl.qameta.io/artifactory/helm
helm repo update
helm upgrade --install testops qameta/testops -f values.yaml 
```

### First run and application init

Application creates and updates the database schema to the actual state of selected release during its first run. This process could take considerable time, and readiness probes could fail, hence for the very first run, and in case of data migrations, we recommend disabling the probes.

For the sake of this very example, we operating in the namespace `testops` which could differ from yours, so copy the commands copy and execute commands consciously after checking them against the reality.

```yaml
helm upgrade --install testops qameta/testops \
    -f values.yaml \
    --set=probes.enabled=false \
    --namespace testops \
    --create-namespace \ 
    --wait
```

## TestOps release upgrade

1. update values.yaml `version` to the most recent release (see https://docs.qameta.io/allure-testops/release-notes/)

```yaml
version: 25.3.2
```

2. Run `helm repo update` to get the most recent helm chart data, and then `helm upgrade`

```bash
helm repo update
helm upgrade --install testops qameta/testops \
    -f values.yaml \
    --namespace testops
```

## Azure Special Requirements

Here is an example for deploying minio as S3 solution when running TestOps in Azure.

```shell
# Create Resource Group
az group create --name "testops-azure-minio" --location "WestUS"

# Create Storage Account
az storage account create \
    --name "testops-azure-minio-storage" \
    --kind BlobStorage \
    --sku Standard_LRS \
    --access-tier {your_tier} \
    --resource-group "testops-azure-minio" \
    --location "WestUS"

# Retrieve Account Key    
az storage account show-connection-string \
    --name "testops-azure-minio-storage" \
    --resource-group "testops-azure-minio"

# Create AppService Plan    
az appservice plan create \
    --name "testops-azure-minio-app-plan" \
    --is-linux \
    --sku B1 \
    --resource-group "testops-azure-minio" \
    --location "WestUS"

# Create Minio WebApp    
az webapp create \
    --name "testops-minio-app" \
    --deployment-container-image-name "minio/minio" \
    --plan "testops-azure-minio-app-plan" \
    --resource-group "testops-azure-minio"
    
az webapp config appsettings set \
    --settings "MINIO_ACCESS_KEY={accessKey}" "MINIO_SECRET_KEY={secretKey}" "PORT=9000" \
    --name "testops-minio-app" \
    --resource-group "testops-azure-minio"
    
# Startup command
az webapp config set \
    --startup-file "gateway azure" \
    --name "testops-minio-app" \
    --resource-group "testops-azure-minio"
    
# Then s3 will be available at https://testops-minio-app.azurewebsites.net
```

## Uninstalling the deployment

```bash
helm delete testops --namespace testops
```

Or alternatively you can deleted the namespace, then Kubernetes will remove all components related to the deploy.

```shell
kubectl delete namespace testops
```