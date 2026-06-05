# custom VPC — not using default AWS VPC because it's shared and not secure
# /16 gives us 65,536 IPs — way more than we need but good practice

resource "aws_vpc" "nexcloud_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# internet gateway — without this nothing in the VPC can reach the internet
resource "aws_internet_gateway" "nexcloud_igw" {
  vpc_id = aws_vpc.nexcloud_vpc.id

  tags = {
    Name        = "${var.project_name}-igw-${var.environment}"
    Environment = var.environment
  }
}

# grabbing available AZs dynamically — avoids hardcoding zone names
data "aws_availability_zones" "available" {
  state = "available"
}

# public subnets across 3 AZs — load balancers and NAT gateways live here
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.nexcloud_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  # instances here get public IPs automatically
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}"
    Environment              = var.environment
    "kubernetes.io/role/elb" = "1"
  }
}

# private subnets across 3 AZs — EKS nodes and RDS live here
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.nexcloud_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}"
    Environment                       = var.environment
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# elastic IP for NAT gateway — NAT needs a fixed public IP
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${var.environment}"
  }
}

# NAT gateway in the first public subnet
# private nodes use this to reach the internet without being exposed
resource "aws_nat_gateway" "nexcloud_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-${var.environment}"
  }
}

# public route table — sends internet traffic to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nexcloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nexcloud_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}"
  }
}

# private route table — sends internet traffic through NAT instead
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.nexcloud_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nexcloud_nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${var.environment}"
  }
}

# attaching public route table to all public subnets
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# attaching private route table to all private subnets
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}