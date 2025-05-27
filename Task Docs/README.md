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
- In the search bar, type **Deploy a custom template** and select:
- Deploy a custom template

<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/1.png?raw=true" width="950" alt=""/>

### Step 2: Use the Main Template
- Click on **Build your own template in the editor**.
- In the template editor:

<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/2.png?raw=true" width="950" alt=""/>

- Open your mainTemplate.json file from this link https://raw.githubusercontent.com/lalith2306/SpektraTask/main/Main_Template_working.json.
- Copy the entire content.
- Paste it into the editor.
- Click "**Save**".

  <img src="https://github.com/lalith2306/SpektraTask/blob/main/images/3.png?raw=true" width="950" alt=""/>

### Step 3: Configure Deployment
- Choose your Subscription.
- Select your existing Resource Group or create a new one.
- For the parameters click on **edit parameters**.
- Click on **Load File**.

<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/4.png?raw=true" width="950" alt=""/>

- Select the parameter file stored locally and check the values properly.

<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/5.png?raw=true" width="950" alt=""/>

- Click **Save**.
- Now you will be able to see the parameter values.
  
<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/6.png?raw=true" width="950" alt=""/>

## Step 4: Validation and Deployment
- Click **Review+Create**.
- Check if the template has passed the validation.
- After validation passes click om **create**.
<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/7.png?raw=true" width="950" alt=""/>
**Deployement Successful**

## Step 5: Validate if the role has been assigned to user
- Click on **IAM**
- Click on **Check access**
- Check on User,groups or service principal
- Enter the user name **DemoUser** and select the user
<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/8.png?raw=true" width="950" alt=""/>

Verify the role name assigned

<img src="https://github.com/lalith2306/SpektraTask/blob/main/images/9.png?raw=true" width="950" alt=""/>

## Conclusion

This solution demonstrates a modular, parameterized approach to deploying a secure and manageable network infrastructure in Azure using ARM templates. By separating infrastructure and access control concerns into main and nested templates, this architecture supports flexibility, reusability. The inclusion of a custom role with limited permissions like start/stop VMs, update DNS, and NSG settings ensures that delegated users can operate within well-defined boundaries, enhancing both security and operational efficiency. This setup is ideal for environments that require granular controlled infrastructure management scenarios.
