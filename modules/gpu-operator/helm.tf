resource "helm_release" "gpu-operator" {
  name = "gpu-operator"
  # FIXME set to production product
  repository       = var.helm_repository
  chart            = "gpu-operator"
  namespace        = "gpu-operator"
  create_namespace = true
  version          = var.helm_version
  atomic           = true
  timeout          = 600

  set {
    name  = "nfd.enabled"
    value = var.nfd_enabled
  }

  set {
    name  = "dcgm.enabled"
    value = true
  }

  set {
    name  = "driver.version"
    value = var.driver_version
  }

}
