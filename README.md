# EKS Trunking Check Script

## 📌 Overview
This script **checks whether nodes in an Amazon EKS cluster support trunking** and provides details about:
- **Elastic Network Adapter (ENA) support**
- **Maximum Network Interfaces**
- **Trunking status (enabled or supported)**
- **Formatted output in a clear, readable table**

## 🚀 Features
✅ **Auto-detects EKS cluster name** (no manual input required).  
✅ **Retrieves all EC2 instances running in the cluster**.  
✅ **Fetches instance type details dynamically** from AWS.  
✅ **Checks if trunking is enabled and supported** per instance.  
✅ **Displays EnaSupport (Elastic Network Adapter) requirement**.  
✅ **Formatted output for better readability**.

---

## 🛠️ Prerequisites
Before running the script, ensure:
- You have **AWS CLI installed & configured** (`aws configure`).
- You have **kubectl installed** and connected to your EKS cluster.
- You have **Git installed** if you plan to manage updates.

---

## 📥 Installation
Clone this repository:
```sh
git clone https://github.com/dariushazimi/eks.git
cd eks
```
## Example Output
Checking trunking status for EKS cluster: demo-cluster
|Instance ID|Instance Type|EnaSupport|Max ENIs|Trunking Enabled|Trunking Supported|
|:---:|:---:|:---:|:---:|:---:|:---:|
|03d61603a732e2970|c6.large|required|3|❌ No|❌ No|
|05d86d3d39fc44499|c6.large|required|8|✅ Yes|✅ Yes|
|06937deaf63994995|m5.large|required|4|✅ Yes|✅ Yes|

## 🛠️ Troubleshooting

1️⃣  "No EKS cluster found"

Ensure you have an active cluster by running:

`aws eks list-clusters`

If no clusters appear, that explains it.

2️⃣  "No worker nodes found"

Ensure nodes exist:

`kubectl get nodes`

3️⃣  "Permission denied" when running the script

Fix by granting execution permission:

chmod +x eks-trunking-check.sh 
