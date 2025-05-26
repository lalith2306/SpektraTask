# ARM Template Deployment for Azure Network Infrastructure with RBAC

## Overview

This solution deploys a virtual network infrastructure in Azure with:
- 1 Virtual Network with 2 subnets.
- 2 Virtual Machines, one in each subnet.
- Internet access enabled via public IP.
- Role-based access control using a custom Azure role.

## Objective

This solution provides a modular Azure Resource Manager (ARM) template setup to deploy a network infrastructure with two virtual machines across different subnets and implements Role-Based Access Control (RBAC) by assigning a custom role with limited permissions to a specific user.

## Prequisites

- Active Azure subscription
- Global Admin Privilege Role

## Files needed

- [MainTemplate.json](https://raw.githubusercontent.com/lalith2306/SpektraTask/main/Main_Template_working.json): Deploys VNet, subnets, VMs, and triggers the nested template.
- [NestedTemplate.json](https://raw.githubusercontent.com/lalith2306/SpektraTask/main/NestedRole.json): Creates a custom role and assigns it to a user using users principal ID.
- [Parameters.json](https://github.com/lalith2306/SpektraTask/blob/main/Parameter.json): Parameters required for the deployment.

## Task 

Develope a ARM template to deploy a Network Infrastructure with RBAC

## Step by step guide

### Step 1: Login into Azure portal
- Go to https://portal.azure.com.
- In the search bar, type "Deploy a custom template" and select:
- Deploy a custom template


### Step 2: Use the Main Template
- Click on "Build your own template in the editor".
- In the template editor:
- Open your mainTemplate.json file from this link https://raw.githubusercontent.com/lalith2306/SpektraTask/main/Main_Template_working.json.
- Copy the entire content.
- Paste it into the editor.
- Click "**Save**".

### Step 3: Configure Deployment
- Choose your Subscription.
- Select your existing Resource Group or create a new one.
- For the parameters click on edit parameters.
- Click on Load File.
- Select the parameter file stored locally and check the values properly.
- Click Save.
- Now you will be able to see the parameter values.

## Step 4: Validation and Deployment
- Check if the template has passed the validation.
- Click Create.
  


