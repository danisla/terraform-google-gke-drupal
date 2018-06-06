variable "project" {
  description = "The project to deploy to, if not set the default provider project is used."
  default     = ""
}

variable "region" {
  description = "The region to deploy to"
  default     = "us-central1"
}

variable "zone" {
  description = "The zone to deploy to"
  default     = "us-central1-f"
}

variable "network" {
  description = "The network to deploy to"
  default     = "default"
}

variable "network_project" {
  description = "Name of the project for the network. Useful for shared VPC. Default is var.project."
  default     = ""
}

variable "subnetwork" {
  description = "The subnetwork to deploy to"
  default     = "default"
}

variable "name" {
  description = "The name of the GKE cluster"
  default     = "tf-gke-drupal"
}

variable "helm_version" {
  default = "v2.9.1"
}

variable "drupal_chart_version" {
  default = "0.11.18"
}

variable "nginx_ingress_chart_version" {
  default = "0.20.1"
}

variable "kube_lego_chart_version" {
  default = "0.4.2"
}

variable "app_name" {
  default = "drupal"
}

variable "acme_email" {}

variable "acme_url" {
  default = "https://acme-v01.api.letsencrypt.org/directory"
}
