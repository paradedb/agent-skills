> ## Documentation Index
> Fetch the complete documentation index at: https://docs.paradedb.com/llms.txt
> Use this file to discover all available pages before exploring further.

# ParadeDB BYOC

> Deploy ParadeDB Bring Your Own Cloud (BYOC) within your cloud environment

<Info>
  For access to ParadeDB BYOC, [contact sales](mailto:sales@paradedb.com).
</Info>

ParadeDB BYOC (Bring Your Own Cloud) is a managed deployment of ParadeDB within your cloud environment.
It combines the benefits of a managed platform with the security posture of a self-hosted deployment.

ParadeDB BYOC is supported on GCP and AWS, including GovCloud regions and airgapped environments.
To request access for Azure, Oracle Cloud, or another cloud platform please contact [sales@paradedb.com](mailto:sales@paradedb.com).

## How BYOC Works

ParadeDB BYOC provisions a Kubernetes cluster in your cloud environment with [high availability](/deploy/self-hosted/high-availability) preconfigured.
It also configures [logical replication](/deploy/logical-replication/getting-started) with your primary Postgres, backups, connection pooling, monitoring, access control, and audit logging.

ParadeDB BYOC can be deployed and managed in one of two ways:

* **Fully Managed**: ParadeDB will deploy and manage the ParadeDB BYOC module for you. ParadeDB requires a sub-account or project within your cloud provider via an IAM user or a service account.
* **Just-in-Time Managed**: You will deploy the ParadeDB BYOC module and can choose to provide just-in-time access to the ParadeDB team when support is required. This is typically useful for airgapped environments.

<img src="https://mintcdn.com/paradedb/EnFi_28R6H66KMiU/images/topology.png?fit=max&auto=format&n=EnFi_28R6H66KMiU&q=85&s=8227fc667a879d9b8afff5ad3a144363" alt="ParadeDB BYOC Topology" width="10528" height="6208" data-path="images/topology.png" />

## Getting Started

This section assumes that you have received access to the ParadeDB BYOC module and are deploying it yourself on AWS or GCP.
In a fully managed deployment, these steps will be performed by ParadeDB on your behalf.

### Install Dependencies

First, ensure that you are in the BYOC module repository. Next, install Terraform, Kubectl, PostgreSQL, and the CLI for your desired cloud provider:

<CodeGroup>
  ```bash macOS theme={null}
  brew install terraform kubectl postgresql
  ```

  ```bash Ubuntu theme={null}
  sudo apt-get install -y terraform kubectl postgresql
  ```
</CodeGroup>

### Authenticate CLI

Install and authenticate with either the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) or [GCP CLI](https://cloud.google.com/sdk/docs/install#deb).

<CodeGroup>
  ```bash AWS theme={null}
  aws configure
  ```

  ```bash GCP theme={null}
  gcloud init
  gcloud auth application-default login
  ```
</CodeGroup>

### Provision ParadeDB

Our Terraform project will provision a Kubernetes cluster (EKS or GKE) along with all the necessary infrastructure to run ParadeDB.

First, copy either `aws.example.tfvars` or `gcp.example.tfvars` into a new file called `byoc.tfvars`.

<CodeGroup>
  ```bash AWS theme={null}
  cp aws.example.tfvars byoc.tfvars
  ```

  ```bash GCP theme={null}
  cp gcp.example.tfvars byoc.tfvars
  ```
</CodeGroup>

Next, open and configure `byoc.tfvars`. Configuration instructions can be found directly within the file.

```bash theme={null}
open byoc.tfvars || xdg-open byoc.tfvars
```

### Run Terraform

First, initialize Terraform.

<CodeGroup>
  ```bash AWS theme={null}
  terraform -chdir=infrastructure/aws init
  ```

  ```bash GCP theme={null}
  terraform -chdir=infrastructure/gcp init
  ```
</CodeGroup>

Next, run Terraform `apply`.

<CodeGroup>
  ```bash AWS theme={null}
  terraform -chdir=infrastructure/aws apply -var-file=../../byoc.tfvars
  ```

  ```bash GCP theme={null}
  terraform -chdir=infrastructure/gcp apply -var-file=../../byoc.tfvars
  ```
</CodeGroup>

<Note>
  It may take up to 30 minutes to provision all the necessary infrastructure.
</Note>

When this command is complete, you will see a `kubectl` command printed as Terraform output to the terminal.
Run this command, which will add the EKS or GKE cluster configuration to your local `.kubeconfig` file.

That's it! You're now ready to connect to ParadeDB.

### Connect to ParadeDB

#### Access the Grafana Dashboard

First, port-forward the Grafana service to localhost.

```bash theme={null}
kubectl --namespace monitoring port-forward service/prometheus-grafana 8080:80
```

Then, go to `http://localhost:8080`. Your Grafana credentials have been printed in the terminal output of the above Terraform `apply` command.

You can find the ParadeDB dashboard by typing `CloudNativePG` in the search bar, and selecting `paradedb` for the Database Namespace.

By default, the dashboard will display metrics over the last 7 days. If you've just spun up the cluster, change it to the last 15 minutes to start seeing results immediately.

#### Access the ParadeDB Instance

First, retrieve the database credentials.

```bash theme={null}
kubectl --namespace paradedb get secrets paradedb-superuser -o json | jq -r '.data | map_values(@base64d) | .uri |= sub("\\*"; "paradedb") | .dbname = "paradedb"'
```

Next, port-forward the ParadeDB service to localhost.

```bash theme={null}
kubectl --namespace paradedb port-forward service/paradedb-rw 5432:5432
```

Now you can connect to the ParadeDB instance using the credentials you've retrieved.

```bash theme={null}
PGPASSWORD=<your-password> psql -h localhost -d paradedb -p 5432 -U <your-user>
```
