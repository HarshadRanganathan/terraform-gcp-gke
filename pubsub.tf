resource "google_pubsub_topic" "gke_notifications" {
  name    = "${local.cluster_name}-notifications"
  project = var.project_id
}