# 🚀 EKS Health Check Script

A **comprehensive health check script** for **Amazon EKS clusters**, providing detailed insights into cluster status, node health, security settings, and installed plugins.

## 📌 Features
✅ Checks **EKS cluster status** and **public access configuration**  
✅ Validates **IAM role permissions** and **AWS security groups**  
✅ Retrieves **EKS Insights** to detect potential upgrade issues  
✅ Checks **installed plugins** and **running DaemonSets/StatefulSets**  
✅ Monitors **pod restarts, resource utilization, and disk usage**  
✅ **Formatted output tables** for easy readability  

## 🔧 Installation
Ensure you have the following installed:
- **AWS CLI** (configured with the necessary permissions)
- **kubectl** (connected to your EKS cluster)
- **jq** (for JSON processing)

### **Install Dependencies on Linux/macOS**
```sh
sudo apt install awscli jq -y  # For Ubuntu/Debian
brew install awscli jq          # For macOS


```

```
./eks_health_check.sh <eks-cluster-name>
```

========================================
🔍 **EKS Cluster Health Check**
========================================
✅ AWS Account ID   : 7000000000
🔍 Checking EKS Cluster Details...
✅ Cluster Name      : demo-cluster
✅ Kubernetes Version: 1.30
✅ Cluster Status    : ACTIVE
✅ Public Access     : ⚠️ Enabled (Security Risk)
🔍 Checking IAM Role Permissions...
✅ EKS IAM Role: arn:aws:iam::3333333330:role/DemoClusterRole
🔍 Checking AWS Security Groups...
---------------------------------------------------------------------------------
Security Group Name                                      Group ID                
---------------------------------------------------------------------------------
eks-cluster-sg-demo-cluster-2096                   sg-0dff6748462ca     
eksctl-demo-cluster-cluster-ClusterSharedNodeSecurity..  sg-04f0a6c49b0     
---------------------------------------------------------------------------------
🔍 Checking DaemonSets & StatefulSets...
---------------------------------------------------------------------------------
NAMESPACE       NAME                                     READY    AGE       
---------------------------------------------------------------------------------
default         retail-store-app-catalog-mysql           1/1      2d2h                
default         retail-store-app-orders-postgresql       1/1      2d2h                
---------------------------------------------------------------------------------
🔍 Checking AWS EKS Insights...
-----------------------------------------------------------------------------------------
Insight Name                                  Status          Description                                       
-----------------------------------------------------------------------------------------
EKS add-on version compatibility              PASSING         Checks version compatibility for add-ons         
Kubelet version skew                          PASSING         Ensures kubelet versions follow policy          
-----------------------------------------------------------------------------------------
✅ **EKS Health Check Completed.**
========================================


