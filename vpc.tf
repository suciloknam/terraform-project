resource "aws_vpc" "local_vpc" {
            cidr_block = "10.0.0.0/16"
            enable_dns_hostnames = true
            enable_dns_support = true
            tags = {
              "Name" = "aws_vpc1"
            }
}

variable "vpcok_availability_zones" {
  description = "Value "
  type        = list(string)
  default     = ["ap-south-1a","ap-south-1b"]
}

resource "aws_subnet" "public_subnet1" {
  count = length(var.vpcok_availability_zones) 
  vpc_id = aws_vpc.local_vpc.id
  cidr_block = cidrsubnet(aws_vpc.local_vpc.cidr_block, 8,count.index + 1)
  availability_zone = var.vpcok_availability_zones[count.index]
  tags = {
    "Name" = "pok-public_subnet1-${count.index + 1}"
  }
}
 

resource "aws_subnet" "private_subnet1" {
  count = length(var.vpcok_availability_zones) 
  vpc_id = aws_vpc.local_vpc.id
  cidr_block = cidrsubnet(aws_vpc.local_vpc.cidr_block, 8,count.index + 3)
  availability_zone = var.vpcok_availability_zones[count.index]
  tags = {
    "Name" = "pok-private_subnet1-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.local_vpc.id

  tags = {
    Name = "pok-internet-gateway"
  }
}

resource "aws_route_table" "route_table_for_pok" {
  vpc_id = aws_vpc.local_vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table-for-public-subnet"
  }
}

resource "aws_route_table_association" "route_table_public_subnet" {
   route_table_id = aws_route_table.route_table_for_pok.id
   count = length(var.vpcok_availability_zones)
   subnet_id = element(aws_subnet.public_subnet1[*].id,count.index)
}

resource "aws_eip" "eip" {
  domain = "vpc"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "pok-nat-gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.public_subnet1[*].id.0)

  tags = {
    Name = "pok-nat-gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}
 
resource "aws_route_table" "route_table_for_pok_private" {
  depends_on = [aws_nat_gateway.pok-nat-gateway]
  vpc_id = aws_vpc.local_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route-table-for-private-subnet"
  }
}

resource "aws_route_table_association" "route_table_private_subnet" {
   route_table_id = aws_route_table.route_table_for_pok_private.id
   count = length(var.vpcok_availability_zones)
   subnet_id = element(aws_subnet.private_subnet1[*].id,count.index)
}
