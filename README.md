# Azure Traffic Route Terraform Deployment

## Purpose

This repository contains Infrastructure as Code (IaC) using Terraform to automate the deployment of a secure network topology in Azure.
**It provisions:**

- A Virtual Network (VNET)
- Public and Private Subnets
- A Network Virtual Appliance (NVA) VM
- A Public VM (in the public subnet)
- A Private VM (in the private subnet)
- A Route Table to route traffic from the Public VM to the Private VM via the NVA

This setup is useful for scenarios where you want to inspect, filter, or control traffic between public and private resources using a custom appliance (NVA).

---

## Architecture Overview

![Architecture Overview](/attachments/Azure_traffic_routing.png)

- **Public VM**: Just for simulation of purpose. But the VM is accessible internally only via Bations host.
- **Private VM**: Only accessible via the NVA.
- **NVA VM**: Acts as a router/firewall between public and private subnets.
- **Route Table**: Ensures traffic from the Public VM to the Private VM is routed through the NVA.

---

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.10.5 or later
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure subscription with sufficient permissions

---

## Setup Instructions

### 1. Clone the Repository

```sh
git clone <repository-url>
cd tf-test-azure-traffic-route
```

### 2. Authenticate with Azure

```sh
az login
az account set --subscription "<your-subscription-id>"
```

### 3. Configure Variables

Edit `terraform.tfvars` with your Azure credentials and desired region:

```hcl
subscription_id = "your-azure-subscription-id"
client_id       = "your-azure-client-id"
client_secret   = "your-azure-client-secret"
tenant_id       = "your-azure-tenant-id"
location        = "australiaeast"
```

### 4. Initialize Terraform

```sh
terraform init
```

### 5. Review the Plan

```sh
terraform plan
```

### 6. Apply the Configuration

```sh
terraform apply
```

---

## Clean Up

To destroy all resources:

```sh
terraform destroy
```

---

## Files

- `main.tf`: Main resource definitions (VNET, subnets, VMs, NVA, route table)
- `variables.tf`: Input variables
- `terraform.tfvars`: Variable values (user-supplied)
- `provider.tf`: Azure provider configuration

---

## References

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Virtual Network Document](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Route Network traffic witha a route table](https://learn.microsoft.com/en-us/azure/virtual-network/tutorial-create-route-table?tabs=portal)
