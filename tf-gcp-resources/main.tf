provider "google" {
  region  = var.region
  project = var.project
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

data "google_project" "vault" {
  project_id = var.project_id
}

# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server"
  display_name = "Vault Server"
  project      = data.google_project.vault.project_id
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = data.google_project.vault.project_id
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}

# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = data.google_project.vault.project_id
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

# KMS setup

# Create the KMS key ring
resource "google_kms_key_ring" "vault-unseal" {
  name     = "vault-unseal"
  location = var.region
  project  = data.google_project.vault.project_id

  depends_on = [google_project_service.service]
}

# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-unseal-key1" {
  name            = "vault-unseal-key1"
  key_ring        = google_kms_key_ring.vault-unseal.id
  rotation_period = "604800s"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-unseal" {
  crypto_key_id = google_kms_crypto_key.vault-unseal-key1.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}


# Try with a global key ring

# Create a KMS key ring
resource "google_kms_key_ring" "vault-unseal-global" {
  project  = data.google_project.vault.project_id
  name     = "vault-unseal-global"
  location = "global"
}

# Create a crypto key for the key ring
resource "google_kms_crypto_key" "vault-unseal-key2" {
  name            = "vault-unseal-key2"
  key_ring        = google_kms_key_ring.vault-unseal-global.id
  rotation_period = "604800s"
}

  # Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-unseal-global" {
  crypto_key_id = google_kms_crypto_key.vault-unseal-key2.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}