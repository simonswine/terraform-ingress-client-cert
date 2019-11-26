variable "environment" {
  default = "development"
}

# CA certificate
resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = tls_private_key.ca.algorithm
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name = "Example CA ${var.environment} CA"
  }

  is_ca_certificate = true

  # 10 years
  validity_period_hours = 87660

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_private_key" "server" {

  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "server" {
  key_algorithm   = tls_private_key.server.algorithm
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name = "server-cert-super-secure.cloud"
  }

  dns_names = [
    "server-cert-super-secure.cloud",
  ]

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem = tls_cert_request.server.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.ca.key_algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  # 1 year
  validity_period_hours = 8766

  # mark the certificate for renewal 30 days before expiry
  early_renewal_hours = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "tls_private_key" "client" {

  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "client" {
  key_algorithm   = tls_private_key.client.algorithm
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name = "client-cert-super-secure"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem = tls_cert_request.client.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.ca.key_algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  # 1 year
  validity_period_hours = 8766

  # mark the certificate for renewal 30 days before expiry
  early_renewal_hours = 720

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "local_file" "secrets" {
  content         = <<EOS
apiVersion: v1
kind: Secret
metadata:
  name: ca-secret
  namespace: default
type: Opaque
data:
  ca.crt: ${base64encode(tls_self_signed_cert.ca.cert_pem)}
  #ca.crl: addmeifneeded
---
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  ca.crt: ${base64encode(tls_self_signed_cert.ca.cert_pem)}
  tls.crt: ${base64encode(tls_locally_signed_cert.server.cert_pem)}
  tls.key: ${base64encode(tls_private_key.server.private_key_pem)}
  #ca.crl: addmeifneeded
EOS
  filename        = "${path.module}/secrets.yaml"
  file_permission = 0600
}

resource "local_file" "client-crt" {
  content         = tls_locally_signed_cert.client.cert_pem
  filename        = "${path.module}/client.crt"
  file_permission = 0644
}

resource "local_file" "client-key" {
  content         = tls_private_key.client.private_key_pem
  filename        = "${path.module}/client.key"
  file_permission = 0600
}

resource "local_file" "ca-crt" {
  content         = tls_self_signed_cert.ca.cert_pem
  filename        = "${path.module}/ca.crt"
  file_permission = 0644
}



