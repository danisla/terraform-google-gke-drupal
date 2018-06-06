output cluster_name {
  description = "The name of the GKE cluster"
  value       = "${google_container_cluster.default.name}"
}

output cluster_region {
  description = "The GKE cluster region"
  value       = "${var.region}"
}

output cluster_zone {
  description = "The GKE cluster zone"
  value       = "${google_container_cluster.default.zone}"
}

output "endpoint" {
  description = "URL to the Drupal service"
  value       = "https://${google_endpoints_service.openapi_service.service_name}"
}

output "drupal_user" {
  description = "The default drupal username"
  value       = "user"
}

output "drupal_password" {
  description = "The default drupal user password"
  value       = "${random_id.drupal_password.b64_std}"
}
