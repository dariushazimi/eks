#!/bin/bash

# Author:  Dariush Azimi
# Updated: March 6, 2025
usage() {
    echo "Usage: $0 <eks-cluster-name>"
    exit 1
}

# Check if cluster name is provided
if [ -z "$1" ]; then
    echo "❌ Missing cluster name!"
    usage
fi

CLUSTER_NAME="$1"

# Ensure required tools are installed
for cmd in aws kubectl jq column; do
    command -v $cmd >/dev/null 2>&1 || { echo "❌ $cmd is not installed. Exiting."; exit 1; }
done

echo "========================================"
echo "🔍 **EKS Cluster Health Check**"
echo "========================================"

# Get AWS Account Number
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Unable to retrieve AWS Account ID. Check AWS CLI authentication."
    exit 1
fi
echo "✅ AWS Account ID   : $AWS_ACCOUNT_ID"

# Fetch Cluster Information
echo "🔍 Checking EKS Cluster Details..."
CLUSTER_INFO=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster" --output json 2>/dev/null)

if [ -z "$CLUSTER_INFO" ]; then
    echo "❌ Failed to fetch cluster details. Ensure cluster name is correct."
    exit 1
fi

CLUSTER_STATUS=$(echo "$CLUSTER_INFO" | jq -r '.status')
K8S_VERSION=$(echo "$CLUSTER_INFO" | jq -r '.version')
PUBLIC_ACCESS=$(echo "$CLUSTER_INFO" | jq -r '.resourcesVpcConfig.endpointPublicAccess')

echo "✅ Cluster Name      : $CLUSTER_NAME"
echo "✅ Kubernetes Version: $K8S_VERSION"
echo "✅ Cluster Status    : $CLUSTER_STATUS"
echo "✅ Public Access     : $(if [ "$PUBLIC_ACCESS" == "true" ]; then echo "⚠️ Enabled (Security Risk)"; else echo "✅ Disabled"; fi)"

# Check IAM Role Permissions
echo "🔍 Checking IAM Role Permissions..."
EKS_ROLE_ARN=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.roleArn" --output text)
if [ -n "$EKS_ROLE_ARN" ]; then
    echo "✅ EKS IAM Role: $EKS_ROLE_ARN"
else
    echo "❌ EKS IAM Role not found!"
fi

# Check AWS Security Groups (Formatted)
echo "🔍 Checking AWS Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName, GroupId]' --output json 2>/dev/null)

if [ -z "$SECURITY_GROUPS" ]; then
    echo "⚠️ No security groups found."
else
    echo "------------------------------------------------------------------------------------------------------"
    printf "%-60s %-25s\n" "Security Group Name" "Group ID"
    echo "------------------------------------------------------------------------------------------------------"
    echo "$SECURITY_GROUPS" | jq -r '.[] | @tsv' | awk -F"\t" '{printf "%-60s %-25s\n", substr($1, 1, 60), $2}'
    echo "------------------------------------------------------------------------------------------------------"
fi


# Check DaemonSets & StatefulSets (Formatted)
echo "🔍 Checking DaemonSets & StatefulSets..."
DAEMONSETS=$(kubectl get daemonsets --all-namespaces --no-headers 2>/dev/null)
STATEFULSETS=$(kubectl get statefulsets --all-namespaces --no-headers 2>/dev/null)
if [ -z "$DAEMONSETS" ] && [ -z "$STATEFULSETS" ]; then
    echo "✅ No issues with DaemonSets or StatefulSets."
else
    echo "---------------------------------------------------------------------------------"
    printf "%-15s %-40s %-8s %-10s\n" "NAMESPACE" "NAME" "READY" "AGE"
    echo "---------------------------------------------------------------------------------"
    [ -n "$DAEMONSETS" ] && echo "$DAEMONSETS" | awk '{printf "%-15s %-40s %-8s %-10s\n", $1, $2, $3, $5}'
    [ -n "$STATEFULSETS" ] && echo "$STATEFULSETS" | awk '{printf "%-15s %-40s %-8s %-10s\n", $1, $2, $3, $5}'
    echo "---------------------------------------------------------------------------------"
fi

# Check AWS EKS Insights (Formatted)
echo "🔍 Checking AWS EKS Insights..."
INSIGHTS=$(aws eks list-insights --cluster-name "$CLUSTER_NAME" --query 'insights[*].[name, insightStatus.status, description]' --output json 2>/dev/null)

if [ -z "$INSIGHTS" ] || [ "$INSIGHTS" == "[]" ]; then
    echo "✅ No critical EKS insights detected."
else
    echo "-----------------------------------------------------------------------------------------"
    printf "%-45s %-15s %-50s\n" "Insight Name" "Status" "Description"
    echo "-----------------------------------------------------------------------------------------"
    echo "$INSIGHTS" | jq -r '.[] | @tsv' | awk -F"\t" '{printf "%-45s %-15s %-50s\n", $1, $2, $3}'
    echo "-----------------------------------------------------------------------------------------"
fi

# List Installed Plugins & Versions (Formatted)
echo "🔍 Listing Installed EKS Plugins & Versions..."
PLUGINS=$(kubectl get pods -n kube-system -o json | jq -r '.items[] | select(.metadata.labels["k8s-app"]) | .metadata.labels["k8s-app"] + " -> " + (.status.containerStatuses[].image // "Unknown")' 2>/dev/null)
if [ -z "$PLUGINS" ]; then
    echo "⚠️ No installed plugins detected."
else
    echo "---------------------------------------------------------------------------------"
    printf "%-40s %-50s\n" "Plugin Name" "Version"
    echo "---------------------------------------------------------------------------------"
    echo "$PLUGINS" | awk -F" -> " '{printf "%-40s %-50s\n", $1, $2}'
    echo "---------------------------------------------------------------------------------"
fi

echo "========================================"
echo "✅ **EKS Health Check Completed.**"
echo "========================================"

