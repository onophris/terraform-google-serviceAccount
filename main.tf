# Provides information on GCP provider config
data "google_client_config" "default" {}

# Locals variables : Module logic
locals {
  iam_permissions = [
    for k, v in var.iam:
    { "role" = k, "members" = v}
  ]
}

# Provision a Service Account for the cluster
resource "google_service_account" "default" {
    account_id      = "${var.name}"
    display_name    = "${var.description}"
    project         = "${length(var.project) > 0 ? var.project : data.google_client_config.default.project}"
}

# Potentially use for exporting Keys 
#
# Massive Security Risk! Ensure PGP encryption is enabled and repo is encrypted
#
resource "google_service_account_key" "default" {
  # check if key map is set
  count               = "${lookup(var.key, "enabled") != "false" ? 1 : 0}" 

  service_account_id  = "projects/${length(var.project) > 0 ? var.project : data.google_client_config.default.project}/serviceAccounts/${google_service_account.default.email}"
  key_algorithm       = "${lookup(var.key, "key_algorithm", "KEY_ALG_RSA_2048")}"
  public_key_type     = "${lookup(var.key, "public_key_type", "TYPE_X509_PEM_FILE")}"
  private_key_type    = "${lookup(var.key, "private_key_type", "TYPE_GOOGLE_CREDENTIALS_FILE")}"

  pgp_key             = "${lookup(var.key, "pgp_key", "")}"
  depends_on = ["google_service_account.default"]
}

# Service Account Binding Policy
# Use this if you want to use service account as a Resource.
# For SA that need to be used as an identity set IAM permissions at project level
resource "google_service_account_iam_binding" "default" {
    count               = "${length(local.iam_permissions) > 0 ? length(local.iam_permissions) : 0}"

    service_account_id  = "projects/${length(var.project) > 0 ? var.project : data.google_client_config.default.project}/serviceAccounts/${google_service_account.default.email}"
    role    = "${trimspace(local.iam_permissions[count.index].role)}"

    members = "${compact(local.iam_permissions[count.index].members)}"

    depends_on = ["google_service_account.default"]
}