# As we're doing operations on Kubernetes objects, we need the kubernetes
# provider.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.context
}
