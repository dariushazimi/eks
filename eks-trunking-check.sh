#!/bin/bash
# Created by: Dariush Azimi
# Updated: March 6, 2025
# Get EKS Cluster Name (automatically fetch the first cluster found)
CLUSTER_NAME=$(aws eks list-clusters --query "clusters[0]" --output text)

if [[ -z "$CLUSTER_NAME" || "$CLUSTER_NAME" == "None" ]]; then
    echo "No EKS cluster found. Exiting."
    exit 1
fi

echo "Checking trunking status for EKS cluster: $CLUSTER_NAME"
echo ""

# Get all EC2 instance IDs from active Kubernetes nodes
INSTANCE_IDS=$(kubectl get nodes -o jsonpath='{.items[*].metadata.name}')

if [[ -z "$INSTANCE_IDS" ]]; then
    echo "No worker nodes found in the cluster. Exiting."
    exit 1
fi

# Get a dynamic list of instance families that support trunking
SUPPORTED_TRUNKING_FAMILIES=$(aws ec2 describe-instance-types --query 'InstanceTypes[?NetworkInfo.EnaSupport==`required` && NetworkInfo.MaximumNetworkInterfaces>`4`].InstanceType' --output text | awk -F. '{print $1}' | sort -u)

# Print table header with formatted spacing
printf "%-20s %-15s %-12s %-10s %-18s %-20s\n" "Instance ID" "Instance Type" "EnaSupport" "Max ENIs" "Trunking Enabled" "Trunking Supported"
printf "%s\n" "------------------------------------------------------------------------------------------------------------------"

# Loop through each node and check instance type & trunking
for INSTANCE_ID in $INSTANCE_IDS; do
    # Get the instance type
    INSTANCE_TYPE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[*].Instances[*].InstanceType" --output text)

    # Extract the instance family
    INSTANCE_FAMILY=$(echo "$INSTANCE_TYPE" | awk -F. '{print $1}')

    # Get EnaSupport and MaximumNetworkInterfaces
    INSTANCE_DETAILS=$(aws ec2 describe-instance-types --instance-types "$INSTANCE_TYPE" --query "InstanceTypes[0].[NetworkInfo.EnaSupport, NetworkInfo.MaximumNetworkInterfaces]" --output text)
    
    # Split the values into separate variables
    ENA_SUPPORT=$(echo "$INSTANCE_DETAILS" | awk '{print $1}')
    MAX_ENI=$(echo "$INSTANCE_DETAILS" | awk '{print $2}')

    # Check if the instance family supports trunking dynamically
    if echo "$SUPPORTED_TRUNKING_FAMILIES" | grep -q "$INSTANCE_FAMILY"; then
        TRUNK_SUPPORT="✅ Yes"
    else
        TRUNK_SUPPORT="❌ No"
    fi

    # Check if the instance has a trunk interface
    TRUNK_COUNT=$(aws ec2 describe-network-interfaces --filters "Name=interface-type,Values=trunk" "Name=attachment.instance-id,Values=$INSTANCE_ID" --query "length(NetworkInterfaces)" --output text)

    # Determine if trunking is enabled
    if [[ "$TRUNK_COUNT" -gt 0 ]]; then
        TRUNK_ENABLED="✅ Yes"
    else
        TRUNK_ENABLED="❌ No"
    fi

    # Print the formatted results
    printf "%-20s %-15s %-12s %-10s %-18s %-20s\n" "$INSTANCE_ID" "$INSTANCE_TYPE" "$ENA_SUPPORT" "$MAX_ENI" "$TRUNK_ENABLED" "$TRUNK_SUPPORT"
done

