variable acme_email {}

variable region {
  default = "us-west1"
}

variable zone {
  default = "us-west1-b"
}

variable network_name {
  default = "tf-gke-drupal"
}

provider google {
  region = "${var.region}"
}

resource "google_compute_network" "default" {
  name                    = "${var.network_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.network_name}"
  ip_cidr_range            = "10.127.0.0/20"
  network                  = "${google_compute_network.default.self_link}"
  region                   = "${var.region}"
  private_ip_google_access = true
}

module "drupal" {
  source     = "../../"
  region     = "${var.region}"
  zone       = "${var.zone}"
  network    = "${google_compute_network.default.name}"
  subnetwork = "${google_compute_subnetwork.default.name}"
  acme_email = "${var.acme_email}"
}

output "endpoint" {
  value = "${module.drupal.endpoint}"
}

output "drupal_user" {
  value = "${module.drupal.drupal_user}"
}

output "drupal_password" {
  value = "${module.drupal.drupal_password}"
}

output "gke" {
  value = "gcloud container clusters get-credentials --zone ${var.zone} ${module.drupal.cluster_name}"
}
