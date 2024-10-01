# oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter
resource "helm_release" "kubernetes-event-exporter" {
  depends_on       = [helm_release.loki]
  repository       = "oci://registry-1.docker.io/bitnamicharts/"
  name             = "kubernetes-event-exporter"
  chart            = "kubernetes-event-exporter"
  namespace        = var.namespace
  create_namespace = true
  # version          = "3.2.12"
  atomic           = true
  values = [
    file("${path.module}/files/kubernetes-event-exporter-values.yaml.tftpl")
  ]

}
