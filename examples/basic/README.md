# Drupal on GKE Basic Example

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/danisla/terraform-google-gke-drupal&page=editor&tutorial=examples/basic/README.md)

## Set up the environment

```
gcloud auth application-default login
export GOOGLE_PROJECT=$(gcloud config get-value project)
```

## Install helm

```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

helm init --client-only
```

## Install the helm provider

MacOS:

```
wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.5.1/terraform-provider-helm_v0.5.1_darwin_amd64.tar.gz
tar -xvf terraform-provider-helm*.tar.gz

mkdir -p ~/.terraform.d/plugins/
mv terraform-provider-helm*/terraform-provider-helm ~/.terraform.d/plugins/
```

Linux:

```
wget https://github.com/mcuadros/terraform-provider-helm/releases/download/v0.5.1/terraform-provider-helm_v0.5.1_linux_amd64.tar.gz
tar -xvf terraform-provider-helm*.tar.gz

mkdir -p ~/.terraform.d/plugins/
mv terraform-provider-helm*/terraform-provider-helm ~/.terraform.d/plugins/
```

## Create the `terraform.tfvars` file

```
cat > terraform.tfvars <<EOF
helm_version = "$(helm version -c --short | egrep -o 'v[0-9].[0-9].[0-9]')"
acme_email = "$(gcloud config get-value account)"
EOF
```

## Run Terraform

```
helm repo update
terraform init
terraform plan
terraform apply
```

## Testing

After the Drupal pods start and are ready, open the interface by navigating to the URL:

```
open https://$(terraform output endpoint)
```

Login with the credentials displayed in the following commands:

```
echo User: $(terraform output drupal_user)
echo Password: $(terraform output drupal_password)
```

## Connecting with kubectl and helm

```
eval $(terraform output gke)

kubectl get pods

helm list
```

## Cleanup

Delete the `nginx-ingress` helm release first so that the forwarding rule and firewall rule are cleaned up by the GCE controller:

```
terraform destroy -target helm_release.nginx-ingress && sleep 60 && \
terraform destroy
```

