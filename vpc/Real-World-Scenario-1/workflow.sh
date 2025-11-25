#!/usr/bin/env bash

#• un VPC isolato e ben segmentato;
#• due subnet pubbliche in due AZ diverse, per l’ALB;
#• due subnet private in due AZ diverse, per le istanze EC2 del backend;
#• un database che deve stare solo in subnet private;
#• accesso a Internet dalle subnet private tramite NAT Gateway;
#• logging del traffico, perché il team di sicurezza vuole capire cosa succede veramente;
#• la possibilità (futura) di automatizzare la creazione di tutto questo con Python, ma per ora ti serve soltanto capire quali componenti toccherebbero un ipotetico script.

# Define VPC and address range, usually a 10.0.0.0/16 network suddivision is great enough
# to be flexible

VPC=$(
    aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
    --query Vpc.VpcId \
    --output text
)

## VPC
echo "VPC:" $VPC

## We need 2 subnets in different zones, 2 for every different zone
PUB_SUBNET_AZ1=$(
    aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-bloc 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specificatoins ResourceType=subnet,Tags=[{Key=Name,Value=az1-pub-subnet}] \
    --query Subnet.SubnetId \
    --output text
) 

PUB_SUBNET_AZ2=$(
    aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-bloc 10.0.2.0/24 \
    --availability-zone us-east-1b \
    --tag-specificatoins ResourceType=subnet,Tags=[{Key=Name,Value=az2-pub-subnet}] \
    --query Subnet.SubnetId \
    --output text
)

PRIV_SUBNET_AZ1=$(
    aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-bloc 10.0.3.0/24 \
    --availability-zone us-east-1a \
    --tag-specificatoins ResourceType=subnet,Tags=[{Key=Name,Value=az1-priv-subnet}] \
    --query Subnet.SubnetId \
    --output text
)

PRIV_SUBNET_AZ2=$(
    aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-bloc 10.0.3.0/24 \
    --availability-zone us-east-1b \
    --tag-specificatoins ResourceType=subnet,Tags=[{Key=Name,Value=az2-priv-subnet}] \
    --query Subnet.SubnetId \
    --output text
)

echo "Public Subnet 1:" $PUB_SUBNET_AZ1
echo "Private Subnet 1:" $PRIV_SUBNET_AZ1
echo "Public Subnet 2:" $PUB_SUBNET_AZ2
echo "Private Subnet 2:" $PRIV_SUBNET_AZ1

# Create an Internet Gateway
IGW=$(
    aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=ProdutcionIGW}]' \
    --query InternetGateway.InternetGatewayId \
    --output text
)

echo "Internet Gateway:" $IGW

# Attach the Internet Gateway
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC

# Create a route table for public subnets
PUB_RT=$(
    aws ec2 create-route-table --vpc-id $VPC \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PublicRouteTable}]' \
    --query RouteTables[].RouteTableId \
    --output text
)

# Create a route table for private sunet in first AZ
PRIV_RT1=$(
    aws ec2 create-route-table --vpc-id $VPC \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivatePublicRouteTable}]' \
    --query RouteTables[].RouteTableId \
    --output text
)

PRIV_RT2=$(
    aws ec2 create-route-table --vpc-id $VPC \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=PrivatePublicRouteTable}]' \
    --query RouteTables[].RouteTableId \
    --output text
)

echo "Public Route Table:" $PUB_RT
echo "Private Route Table 1:" $PRIV_RT1
echo "Private Route Table 2:" $PRIV_RT2

# Add a route to the Internet Gateway
aws ec2 create-route --route-table-id $PUB_RT \
--destination-cidr-blcok 0.0.0.0/0 \
--gateway-id $IGW

# Associate public subnets with the public route table
aws ec2 associate-route-table --route-table-id $PUB_RT \
--subnet-id $PUB_SUBNET_AZ1 

aws ec2 associate-route-table --route-table-id $PUB_RT \
--subnet-id $PUB_SUBNET_AZ2

# Associate private subnets with their respective route tables
aws ec2 associate-route-table --route-table-id $PRIV_RT1 \
--subnet-id $PRIV_SUBNET_AZ1

aws ec2 associate-route-table --route-table-id $PRIV_RT2 \
--subnet-id $PRIV_SUBNET_AZ2

# Create NAT Gateways

# Allocate Elastic IP for NAT Gateway in first AZ
EIP1=$(aws ec2 allocate-address --domain vpc \
--tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=NAT1-EIP}]'
)

EIP2=$(aws ec2 allocate-address --domain vpc \
--tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=NAT2-EIP}]'
)

echo "EIP1 Allocation ID:" $EIP1
echo "EIP2 Allocation ID:" $EIP2

# Create a NAT Gateway in public subnet of first AZ
NAT_GW1=$(
    aws ec2 create-nat-gateway \
    --subnet-id $PUB_SUBNET_AZ1 \
    --allocation-id $EIP1 \
    --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-Gateway1}]'
)

NAT_GW2=$(
    aws ec2 create-nat-gateway \
    --subnet-id $PUB_SUBNET_AZ1 \
    --allocation-id $EIP1 \
    --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=NAT-Gateway1}]'
)

echo "NAT Gateway 1:" $NAT_GW1
echo "NAT Gateway 2:" $NAT_GW2

# Wait for NAT Gateways to be aviable
aws ec2 wait nat-gateway-available -nat-gateway-ids $NAT_GW1
aws ec2 wait nat-gateway-available -nat-gateway-ids $NAT_GW1








