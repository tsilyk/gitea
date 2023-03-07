#----------------------------------------------------------
# Provision:
#  - VPC
#  - Internet Gateway
#  - XX Public Subnets
#  - XX Private Subnets
#  - XX NAT Gateways in Public Subnets to give access to Internet from Private Subnets
#----------------------------------------------------------

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env_app}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env_app}-igw"
  }
}

#-------------Public Subnets and Routing----------------------------------------
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  //enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "${var.env_app}-public-${count.index + 1}"
  }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.env_app}-route-public-subnets"
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}


#-----NAT Gateways with Elastic IPs--------------------------
resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
  tags = {
    Name = "${var.env_app}-nat-gw-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  tags = {
    Name = "${var.env_app}-nat-gw-${count.index + 1}"
  }
}

#--------------Private Subnets and Routing-------------------------
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env_app}-private-${count.index + 1}"
  }
}

resource "aws_route_table" "private_subnets" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = {
    Name = "${var.env_app}-route-private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_routes" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}

#--------------Isolated/Database Subnets ------------------------------------
resource "aws_subnet" "isolated_subnets" {
  count             = length(var.isolated_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.isolated_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.env_app}-isolated-${count.index + 1}"
  }
}

