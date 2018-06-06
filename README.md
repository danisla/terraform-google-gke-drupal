# Drupal on GKE Terraform Module

Creates Drupal deployment on GKE cluster with Helm.

SSL certificates generated with Lets Encrypt (kube-lego) and DNS record provided by Cloud Endpoints.

## Usage

```ruby
module "drupal" {
  source       = "github.com/danisla/terraform-google-gke-drupal"
  region       = "${var.region}"
  acme_email   = "your.email@example.com"
}
```

## Examples

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/danisla/terraform-google-gke-drupal&page=editor&tutorial=examples/basic/README.md)

[basic example](./examples/basic)