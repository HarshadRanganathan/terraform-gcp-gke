data "google_client_config" "default" {}

data "terraform_remote_state" "vpc" {
    backend = "gcs" 
    config = {
        bucket = "${var.stage}-${var.region}-terraform-state"
        prefix = "${var.stage}/vpc/terraform.tfstate"
    }
}
