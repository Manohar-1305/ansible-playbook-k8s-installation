# Security Group for SSH Access
resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow SSH"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow SSH on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Web Traffic
resource "aws_security_group" "web_traffic" {
  name        = "web-traffic"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow HTTP traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# Security Group for NAT Gateway
resource "aws_security_group" "nat_gateway" {
  name        = "nat-gateway-sg"
  description = "Allow all outbound traffic for NAT Gateway"
  vpc_id      = aws_vpc.dev_vpc.id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }
}

# Security Group for Open Access within VPC
resource "aws_security_group" "vpc_access" {
  name        = "open-access-vpc"
  description = "Open access within the VPC"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow all inbound traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }
}

# Security Group for etcd
resource "aws_security_group" "etcd" {
  name        = "etcd-sg"
  description = "Allow etcd traffic"
  vpc_id      = aws_vpc.dev_vpc.id
}

resource "aws_security_group_rule" "etcd_inbound" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"]
  security_group_id = aws_security_group.etcd.id
}


# Security Group for HAProxy
resource "aws_security_group" "haproxy" {
  name        = "haproxy-sg"
  description = "Allow HAProxy HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow HTTP traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow health checks on port 9000"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }
}

# Security Group for Node Ports
resource "aws_security_group" "node_port_group" {
  name        = "node-ports-sg"
  description = "Allow Kubernetes NodePort traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow NodePort range (30000-32767)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }
}

# Security Group for NFS
resource "aws_security_group" "nfs" {
  name        = "nfs-sg"
  description = "Allow NFS traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow NFS traffic (TCP)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Allow NFS traffic (UDP)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Allow portmap (NFS) on port 111"
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kubernetes" {
  name        = "kubernetes"
  description = "Allow Kubernetes API server, kubelet, ELB HTTP/HTTPS"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Allow kubelet traffic"
    from_port   = 10250
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Allow HTTP on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

