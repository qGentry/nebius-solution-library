# Kubernetes for Training in Nebius AI

## Features

- Creating a Kubernetes cluster with CPU and GPU nodes.
- Installing the necessary [Nvidia Gpu Operator](https://github.com/NVIDIA/gpu-operator)
  and [Network Operator](https://docs.nvidia.com/networking/display/cokan10/network+operator) for running GPU
  workloads.- Installing [Grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana).
- Installing [Prometheus](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus).
- Installing [Loki](https://github.com/grafana/loki/tree/main/production/helm/loki).
- Installing [Promtail](https://github.com/grafana/helm-charts/tree/main/charts/promtail).

## Prerequisites
1. Install [Nebius CLI](https://docs.nebius.ai/cli/install/):
    ```bash
    curl -sSL https://storage.ai.nebius.cloud/nebius/install.sh | bash
    ```

2. Reload your shell session:
    ```bash
    exec -l $SHELL
    ```
   or

    ```bash
    source ~/.bashrc
    ```

3. [Configure](https://docs.nebius.ai/cli/configure/) Nebius CLI (it's recommended to use [service account](https://docs.nebius.ai/iam/service-accounts/manage/) for configuration):
    ```bash
    nebius init
    ```

3. Install JQuery (example for Debian based distros):
    ```bash
    sudo apt install jq -y
    ```

## Usage

Follow these steps to deploy the Kubernetes cluster:

1. Load environment variables:
    ```bash
    source ./environment.sh
    ```
2. Initialize Terraform:
    ```bash
    terraform init
    ```
3. Replace the placeholder content
   in `terraform.tfvars` with actual configuration values to fit your specific
   requirements. See the details [bellow](#configuration-variables).
4. Preview the deployment plan:
    ```bash
    terraform plan
    ```
5. Apply the configuration:
    ```bash
    terraform apply
    ```
   Wait for the operation to complete.

## Configuration Variables

These are the basic configurations needed to deploy Kubernetes for Training in Nebius AI. Edit in the configurations that you need in the file `terraform.tfvars`.

There are additional configurable variables in `variables.tf`.

### Environment and network variables
```hcl
# Cloud environment and network
parent_id      = "" # The project-id in this context
subnet_id      = "" # Use the command "nebius vpc v1alpha1 network list" to see the subnet id
ssh_user_name  = "" # Username you want to use to connect to the nodes
ssh_public_key = {
  key  = "put your public ssh key here" OR
  path = "put path to ssh key here"
}
```

### Kubernetes nodes
```hcl
# K8s modes
cpu_nodes_count  = 1 # Number of CPU nodes
cpu_nodes_preset = "16vcpu-64gb" # The CPU node preset
gpu_nodes_count  = 1 # Number of GPU nodes
gpu_nodes_preset = "8gpu-128vcpu-1600gb" # The GPU node preset. Set to "1gpu-16vcpu-200gb", to deploy nodes with 8 GPUs.
```

### Observability options
```hcl
# Observability
enable_grafana    = true # Enable or disable Grafana deployment with true or false
enable_prometheus = true # Enable or disable Prometheus deployment with true or false
enable_loki       = true # Enable or disable Loki deployment with true or false
enable_dcgm       = true # Enable or disable NVIDIA DCGM Exporter Dashboard and Alerting deployment with true or false

## Loki
loki_access_key_id = "" # See the instruction in README.md on how to create this. Leave empty if you are not deploying Loki.
loki_secret_key    = "" # See the instruction in README.md on how to create this. Leave empty if you are not deploying Loki.
```

Check the details below for more information on [Grafana](#grafana), [Prometheus](#prometheus), [Loki](#temporary-block-to-make-loki-work-now) and [NVIDIA DCGM](#nvidia-dcgm-exporter-dashboard-and-alerting).

> Deploying Loki will require you to create a service account! Please check the instructions [here](#temporary-block-to-make-loki-work-now)!

### Storage configuration
```hcl
# Storage
## Filestore - recommended
enable_filestore     = true # Enable or disable Filestore integration with true or false
filestore_disk_size  = 100 * (1024 * 1024 * 1024) #Set Filestore disk size in bytes. The multiplication makes it easier to set the size in GB. This would set the size as 100GB
filestore_block_size = 4096 # Set Filestore block size in bytes

## GlusterFS - legacy
enable_glusterfs = false # Enable or disable GlusterFS integration with true or false
glusterfs_storage_nodes = 3 # Set amount of storage nodes in GlusterFS cluster
glusterfs_disk_count_per_vm = 2 # Set amount of disks per storage node in GlusterFS cluster
glusterfs_disk_size = 100 * (1024 * 1024 * 1024) #Set disk size in bytes. The multiplication makes it easier to set the size in GB. This would set the size as 100GB
```

There are two options available for adding external storage to k8s clusters:

- Filestore (recommended, enabled by default)
- GlusterFS (legacy)

Both would allow creating a Read-Write-Many HostPath PVCs in k8s cluster. Path for Filestore is `/mnt/filestore`, for
GlusterFS it is `/mnt/glusterfs`.

Check [here](#accessing-storage) how to access storage in K8S.

## Connecting to the cluster

### Prepare your environment 
* Install kubectl ([instructions](https://kubernetes.io/docs/tasks/tools/#kubectl))
* Install Nebius AI CLI ([instructions](https://docs.nebius.ai/cli/install)) - also required for deploying the cluster
* Install JQ ([instructions](https://jqlang.github.io/jq/download/)) - also required for deploying the cluster

### Add credentials to the kubectl configuration file
1. Perform this command from the terraform deployment folder:
  ```bash
  nebius mk8s v1 cluster get-credentials --id $(cat terraform.tfstate | jq -r '.resources[] | select(.type == "nebius_mk8s_v1_cluster") | .instances[].attributes.id') --external
  ```
2. Verify the kubectl configuration after adding the credentials:
  ```bash
  kubectl config view
  ```

  The output should resemble::
  ```bash
  apiVersion: v1
  clusters:
    - cluster:
      certificate-authority-data: DATA+OMITTED
  ...
  ```

### Connect to the cluster
Show cluster information:
  ```bash
  kubectl cluster-info
  ```

Get pods:
  ```bash
  kubectl get pods -A
  ```

## Observability

Observability stack is enabled by default. It consist of the following:

- Grafana
- Prometheus
- Loki

### Grafana

Could be disabled by setting follwing in set `enable_grafana` variable to `false` in terraform.tfvars` file.

To access Grafana:

1. **Port-Forward to the Grafana Service:** Run the following command to port-forward to the Grafana service:
   ```sh
   kubectl --namespace o11y port-forward service/grafana 8080:80
   ```

2. **Access Grafana Dashboard:** Open your browser and navigate to `http://localhost:8080`.

3. **Log In:** Use the default credentials to log in:
    - **Username:** `admin`
    - **Password:** `admin`

### Log Aggregation

#### Temporary block to make Loki work now

1. Create an SA
    2. `nebius iam service-account create --parent-id <parent-id> --name <name>`.
2. Add SA to editors group.
    3. Get your tenant id with `nebius iam whoami`.
    4. Get the `editors` group id with: `nebius iam group list --parent-id <tenant-id> | grep -n5 "name: editors"`.
        3. List all members of the `editors` group
           with `nebius iam group-membership list-members --parent-id <group-id>`.
    4. Add your SA to the `editors` group
       with `nebius iam group-membership create --parent-id <group-id> --member-id <sa-id>`
3. Create access key and get its credentials:
    4. `nebius iam access-key create --account-service-account-id <SA-ID> --description 'AWS CLI' --format json`
    5. `nebius iam access-key get-by-aws-id --aws-access-key-id <AWS-KEY-ID-FROM-PREVIOUS-COMMAND> --view secret --format json`
4. Update `loki_access_key_id` and `loki_secret_key` in `terraform.tfvars` with info from the last command.

Log aggregation with the Loki is enabled by default. If you need to disable it, set `enable_loki` variable to `false` in
`terraform.tfvars` file.

To access logs navigate to Loki dashboard `http://localhost:8080/d/o6-BGgnnk/loki-kubernetes-logs`

**NB!** You would have to manually clean loki bucket before doing `terraform destroy`

### Prometheus

Prometheus server is enabled by default. If you need to disable it, set `enable_prometheus` variable to `false` in
terraform.tfvars` file.
Because `DCGM exporter` uses Prometheus as a datasource it will be disabled as well.

To access logs navigate to Node exporter folder `http://localhost:8080/f/e6acfbcb-6f13-4a58-8e02-f780811a2404/`

### NVIDIA DCGM Exporter Dashboard and Alerting

NVIDIA DCGM Exporter Dashboard and Alerting rules are enabled by default. If you need to disable it, set `enable_dcgm`
variable to `false` in terraform.tfvars` file.

By default Alerting rules are created for node groups that has GPUs.

To access NVIDIA DCGM Exporter Dashboard `http://localhost:8080/d/Oxed_c6Wz/nvidia-dcgm-exporter-dashboard`

### Alerting

To enable alert messages for Slack please refer
this [article](https://grafana.com/docs/grafana/latest/alerting/configure-notifications/manage-contact-points/integrations/configure-slack/)

## Accessing Storage

Using mounted storage requires manually creating Persistent Volumes. Bellow is a template for creating PV and PVC.
Replace `<HOST-PATH>` and `<SIZE>` variables with actual values.

```yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: external-storage-persistent-volume
spec:
  storageClassName: csi-mounted-fs-path-sc
  capacity:
    storage: "<SIZE>"
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "<HOST-PATH>" # "/mnt/data/<sub-directory>" or "/mnt/glusterfs/<sub-directory>"

---

kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: external-storage-persistent-volumeclaim
spec:
  storageClassName: csi-mounted-fs-path-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: "<SIZE>"
```


CSI limitations:
limitations of CSI over mounted FS
FS should be mounted to all NodeGroups, because PV attachmend to pod runniing on Node without FS will fail
One PV may fill up to all common FS size
FS size will not be autoupdated if PV size exceed it spec size
FS size for now can't be updated through API, only through NEBOPS. (thread)
volumeMode: Block  - is not possible

Good to know:
read-write many mode PV will work
MSP started testing that solution to enable early integration with mk8s. Hope they will bring feedback soon.
