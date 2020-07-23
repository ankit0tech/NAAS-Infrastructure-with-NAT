provider "aws" {
    region = "ap-south-1"
    profile = "Ankitprofile"
}

resource "aws_key_pair" "keygen" {
  key_name   = "mysecondoskey"
  public_key = file("C:/Users/dell/Desktop/tera/mytest/mykey.pub")
}

resource "aws_security_group" "wpsg" {
  depends_on = [ aws_vpc.myvpc ]
  name        = "WordpressSG"
  description = "Allow SSh inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  } 
  
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow SSH and HTTP for Word Press"
  }
}

resource "aws_security_group" "mysqlsg" {
  depends_on = [ aws_security_group.wpsg, aws_vpc.myvpc ]
  name        = "MysqlSG"
  description = "Allow SSh inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.wpsg.id ]
  } 
  
  ingress {
    description = "Allow mysql"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow SSH and HTTP for sql"
  }
}



resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "Main VPC"
  }
}

resource "aws_subnet" "subnet1" {
  depends_on = [ aws_vpc.myvpc ]
  vpc_id     = aws_vpc.myvpc.id
  availability_zone = "ap-south-1a"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "subnet2" {
  depends_on = [aws_vpc.myvpc]
  vpc_id     = aws_vpc.myvpc.id
  availability_zone = "ap-south-1b"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "mygateway" {
  depends_on = [aws_vpc.myvpc]
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Internet Gateway "
  }
}

resource "aws_route_table" "publictable" {
  depends_on = [aws_vpc.myvpc, aws_internet_gateway.mygateway, aws_subnet.subnet1]
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygateway.id
  }

  tags = {
    Name = "Internet Gateway Table"
  }
}

resource "aws_route_table_association" "associate1" {
  depends_on = [ aws_route_table.publictable ]
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.publictable.id
}

resource "aws_route_table" "privatetable" {
    depends_on = [aws_vpc.myvpc, aws_nat_gateway.mynatgateway, aws_subnet.subnet2]
    vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mynatgateway.id
  }

  tags = {
    Name = "NAT Gateway Table"
  }
}

resource "aws_route_table_association" "associate2" {
    depends_on = [ aws_route_table.privatetable ]
    subnet_id      = aws_subnet.subnet2.id
    route_table_id = aws_route_table.privatetable.id
}

resource "aws_eip" "myip" {
    vpc      = true
}

resource "aws_nat_gateway" "mynatgateway" {
    depends_on = [ aws_eip.myip ]
    allocation_id = aws_eip.myip.id
    subnet_id     = aws_subnet.subnet1.id
}

resource "aws_instance" "WP" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet1.id
  key_name= aws_key_pair.keygen.key_name
  security_groups = [aws_security_group.wpsg.id]
  depends_on = [aws_security_group.wpsg]

  tags = {
    Name = "WordPress"
  }
}

resource "aws_instance" "Mysql" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.subnet2.id
  key_name= aws_key_pair.keygen.key_name
  security_groups = [aws_security_group.mysqlsg.id]
  depends_on = [aws_security_group.mysqlsg]

  tags = {
    Name = "Mysql"
  }
}
