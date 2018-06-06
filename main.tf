provider google {
  region = "${var.region}"
}

data "google_client_config" "current" {}

data "google_compute_network" "default" {
  name = "${var.network}"
}

data "google_compute_subnetwork" "default" {
  name = "${var.subnetwork}"
}

data "google_container_engine_versions" "default" {
  zone = "${var.zone}"
}

resource "google_container_cluster" "default" {
  project            = "${var.project}"
  name               = "${var.name}"
  zone               = "${var.zone}"
  initial_node_count = 3
  min_master_version = "${data.google_container_engine_versions.default.latest_node_version}"
  network            = "${data.google_compute_network.default.name}"
  subnetwork         = "${data.google_compute_subnetwork.default.name}"

  // Use legacy ABAC until these issues are resolved: 
  //   https://github.com/mcuadros/terraform-provider-helm/issues/56
  //   https://github.com/terraform-providers/terraform-provider-kubernetes/pull/73
  enable_legacy_abac = true

  node_config {
    machine_type = "${var.machine_type}"
  }

  // Wait for the GCE LB controller to cleanup the resources.
  provisioner "local-exec" {
    when    = "destroy"
    command = "sleep 90"
  }
}

provider "helm" {
  tiller_image = "gcr.io/kubernetes-helm/tiller:${var.helm_version}"

  kubernetes {
    host                   = "${google_container_cluster.default.endpoint}"
    token                  = "${data.google_client_config.current.access_token}"
    client_certificate     = "${base64decode(google_container_cluster.default.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.default.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)}"
  }
}

resource "google_compute_address" "default" {
  project = "${var.project == "" ? data.google_client_config.current.project : var.project}"
  name    = "tf-gke-helm-${var.app_name}"
  region  = "${var.region}"
}

data "template_file" "openapi_spec" {
  template = "${file("${path.module}/openapi_spec.yaml")}"

  vars {
    endpoint_service = "${var.app_name}-${random_id.endpoint-name.hex}.endpoints.${data.google_client_config.current.project}.cloud.goog"
    target           = "${google_compute_address.default.address}"
  }
}

resource "random_id" "endpoint-name" {
  byte_length = 2
}

resource "google_endpoints_service" "openapi_service" {
  project        = "${var.project == "" ? data.google_client_config.current.project : var.project}"
  service_name   = "${var.app_name}-${random_id.endpoint-name.hex}.endpoints.${data.google_client_config.current.project}.cloud.goog"
  openapi_config = "${data.template_file.openapi_spec.rendered}"
}

resource "helm_release" "kube-lego" {
  name    = "kube-lego"
  chart   = "stable/kube-lego"
  version = "${var.kube_lego_chart_version}"

  values = [<<EOF
rbac:
  create: false
config:
  LEGO_EMAIL: ${var.acme_email}
  LEGO_URL: ${var.acme_url}
  LEGO_SECRET_NAME: lego-acme
EOF
  ]
}

resource "helm_release" "nginx-ingress" {
  name    = "nginx-ingress"
  chart   = "stable/nginx-ingress"
  version = "${var.nginx_ingress_chart_version}"

  values = [<<EOF
rbac:
  create: false
controller:
  service:
    loadBalancerIP: ${google_compute_address.default.address}
EOF
  ]

  depends_on = [
    "helm_release.kube-lego",
  ]
}

resource "random_id" "drupal_password" {
  byte_length = 8
}

resource "helm_release" "drupal" {
  name    = "drupal"
  chart   = "stable/drupal"
  version = "${var.drupal_chart_version}"

  values = [<<EOF
drupalUsername: user
drupalPassword: ${random_id.drupal_password.b64_std}
serviceType: ClusterIP
ingress:
  enabled: true
  hostname: ${google_endpoints_service.openapi_service.service_name}
  tls:
  - hosts:
    - ${google_endpoints_service.openapi_service.service_name}
    secretName: drupal-tls
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    ingress.kubernetes.io/ssl-redirect: "true"
EOF
  ]

  depends_on = [
    "helm_release.kube-lego",
    "helm_release.nginx-ingress",
    "google_container_cluster.default",
  ]
}
