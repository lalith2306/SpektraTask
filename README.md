# ARM Template Deployment for Azure Network Infrastructure with RBAC

## Overview

This solution deploys a virtual network infrastructure in Azure with:
- 1 Virtual Network with 2 subnets.
- 2 Virtual Machines, one in each subnet.
- Internet access enabled via public IP.
- Role-based access control using a custom Azure role.

## Files

- `mainTemplate.json`: Deploys VNet, subnets, VMs, and triggers the nested template.
- `nestedTemplate.json`: Creates a custom role and assigns it to a user.
- `parameters.json`: Parameters required for the deployment.

## Deployment Instructions

1. Replace `<REPLACE_WITH_PRINCIPAL_ID>` in `parameters.json` with the target Azure AD principal ID.
2. Upload the `nestedTemplate.json` to a publicly accessible location or Azure Storage blob.
3. Replace `<REPLACE_WITH_NESTED_TEMPLATE_URI>` in `mainTemplate.json` with the URI of the uploaded nested template.
4. Deploy the template via Azure CLI:

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file mainTemplate.json \
  --parameters @parameters.json
