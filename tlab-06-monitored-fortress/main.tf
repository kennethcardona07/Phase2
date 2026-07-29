terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 1. Close provider block properly
provider "aws" {
  region = "us-east-1"
}

# 2. Data block sits OUTSIDE the provider block
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# ==============================================================================
# IAM Role & Policy for VPC Flow Logs
# ==============================================================================
resource "aws_iam_role" "flow_log_role" {
  name = "Titan-VPC-FlowLogs-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "Titan-VPC-FlowLogs-Policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# IAM Role & Instance Profile for SSM
# ==============================================================================
resource "aws_iam_role" "ssm_role" {
  name = "Titan-EC2-SSM-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "Titan-EC2-SSM-Instance-Profile"
  role = aws_iam_role.ssm_role.name
}

# ==============================================================================
# Step 2A: The Perimeter (VPC, Subnet, IGW, Route Table & Association)
# ==============================================================================
resource "aws_vpc" "titan_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Titan-Prod-VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.titan_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" # Force primary AZ 
  map_public_ip_on_launch = true

  tags = {
    Name = "Titan-Public-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.titan_vpc.id

  tags = {
    Name = "Titan-IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.titan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Titan-Public-RT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ==============================================================================
# Step 2B: The Wiretap (CloudWatch Log Group & VPC Flow Logs)
# ==============================================================================
resource "aws_cloudwatch_log_group" "vpc_logs" {
  name              = "/tkh/titan-prod-vpc-logs"
  retention_in_days = 1
}

resource "aws_flow_log" "titan_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.titan_vpc.id
}

# ==============================================================================
# Step 2C: Zero Trust Compute (Security Group with 0 Ingress + SSM Instance)
# ==============================================================================
resource "aws_security_group" "zero_trust_sg" {
  name        = "Titan-ZeroTrust-SG"
  description = "Zero ingress rules - inbound access via SSM Session Manager only"
  vpc_id      = aws_vpc.titan_vpc.id

  # Allow all outbound traffic for SSM agent telemetry and updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Titan-ZeroTrust-SG"
  }
}
resource "aws_instance" "fortress_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro" # Current generation instance type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.zero_trust_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm_policy,
    aws_iam_instance_profile.ssm_profile,
    aws_internet_gateway.igw,
    aws_route_table_association.public_assoc
  ]

  tags = {
    Name = "Titan-Fortress-Server"
  }
}
