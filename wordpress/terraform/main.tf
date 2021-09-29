# Use the Kubernetes backend for Terraform state so that state is preserved
# between actions.
terraform {
    backend "kubernetes" {}
}

# The namespace resource that we will use to install our application into.
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
  }
}
