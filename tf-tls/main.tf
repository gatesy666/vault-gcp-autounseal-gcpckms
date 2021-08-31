resource "tls_private_key" "ca" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "2048"
}

resource "local_file" "vault_ca_key" {
  content  = tls_private_key.ca.private_key_pem
  filename = "vault_ca_private_key.pem"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm         = tls_private_key.ca.algorithm
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87659

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]

  subject {
    organization        = "IG"
    common_name         = "IG Private Certificate Authority"
    organizational_unit = "IG"
    country             = "GB"
  }
}

resource "local_file" "vault_ca_cert" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "vault_ca_cert.pem"
}

resource "tls_private_key" "vault" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "4096"
}

resource "local_file" "vault_key" {
  content  = tls_private_key.vault.private_key_pem
  filename = "vault_private_key.pem"
}

resource "tls_cert_request" "vault" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vault.private_key_pem

  dns_names    = ["*.gatesy.com","*.vault-internal", "vault-internal.vault.svc.cluster.local", "vault-internal.default.svc.cluster.local", "vault-internal.default.svc", "vault-internal.vault.svc","*.hcv1-vault-internal", "hcv1-vault-internal.vault.svc.cluster.local", "hcv1-vault-internal.default.svc.cluster.local", "hcv1-vault-internal.default.svc", "hcv1-vault-internal.vault.svc","*.hcv2-vault-internal", "hcv2-vault-internal.vault.svc.cluster.local", "hcv2-vault-internal.default.svc.cluster.local", "hcv2-vault-internal.default.svc", "hcv2-vault-internal.vault.svc"]
  ip_addresses = ["127.0.0.1", "172.18.1.128", "172.18.1.129", "172.18.2.128", "172.18.2.129","172.18.1.150","172.18.2.150","172.18.3.150","172.18.4.150"]

  subject {
    common_name         = "*.vault-internal"
    organization        = "IG"
    country             = "GB"
    organizational_unit = "hcvault"
  }
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem   = tls_cert_request.vault.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "vault_cert_pem" {
  content  = tls_locally_signed_cert.vault.cert_pem
  filename = "vault_cert.pem"
}
