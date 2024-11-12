resource "aws_instance" "bastion" {
  ami                  = var.instance_ami_type
  instance_type        = var.instance_type_bastion
  key_name             = "testing-dev-1"
  subnet_id            = aws_subnet.dev_subnet_public_1.id
  iam_instance_profile = data.aws_iam_instance_profile.s3-access-profile.name
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.web_traffic.id,
  ]
  user_data = file("user-script-bastion.sh")

  tags = {
    "Name"                             = "bastion"
    "Environment"                      = "Development"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "null_resource" "pause_before_nfs" {
  provisioner "local-exec" {
    command = "sleep 90"
  }
  depends_on = [aws_instance.bastion]

}
resource "aws_instance" "nfs_server" {
  ami                  = var.instance_ami_type
  instance_type        = var.instance_type_nfs
  key_name             = "testing-dev-1"
  subnet_id            = aws_subnet.dev_subnet_public_1.id
  iam_instance_profile = data.aws_iam_instance_profile.s3-access-profile.name
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.nat_gateway.id,
    aws_security_group.vpc_access.id,
    aws_security_group.nfs.id,
  ]
  user_data = file("user-script-nfs.sh")
  tags = {
    "Name"                             = "nfs"
    "Environment"                      = "Development"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
  depends_on = [null_resource.pause_before_nfs]
}


resource "aws_instance" "load-balancer-server" {
  ami                  = var.instance_ami_type
  instance_type        = var.instance_type_lb
  key_name             = "testing-dev-1"
  subnet_id            = aws_subnet.dev_subnet_public_1.id
  iam_instance_profile = data.aws_iam_instance_profile.s3-access-profile.name
  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.web_traffic.id,
    aws_security_group.vpc_access.id,
    aws_security_group.haproxy.id,
  ]
  user_data = file("user-script-lb.sh")
  tags = {
    "Name"                             = "loadbalancer"
    "Environment"                      = "Production"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
resource "null_resource" "pause_before_master_nodes" {
  provisioner "local-exec" {
    command = "sleep 120"
  }
  depends_on = [aws_instance.bastion, aws_instance.load-balancer-server]
}

resource "aws_instance" "master-server" {
  count                = var.master_instance_count
  ami                  = var.instance_ami_type
  instance_type        = var.instance_type_master
  key_name             = "testing-dev-1"
  subnet_id            = aws_subnet.dev_subnet_private_1.id
  iam_instance_profile = data.aws_iam_instance_profile.s3-access-profile.name
  vpc_security_group_ids = [
    aws_security_group.kubernetes.id,
    aws_security_group.vpc_access.id,
    aws_security_group.etcd.id,
    aws_security_group.nat_gateway.id,
    aws_security_group.node_port_group.id,

  ]
  user_data = file("user-script-node.sh")
  tags = {
    "Name"                             = "master${count.index + 1}"
    "Environment"                      = "Production"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }

  depends_on = [null_resource.pause_before_master_nodes]

}

resource "null_resource" "pause_before_worker_nodes" {
  provisioner "local-exec" {
    command = "sleep 90"
  }

  depends_on = [aws_instance.master-server]

}
resource "aws_instance" "worker-server" {
  depends_on           = [null_resource.pause_before_worker_nodes]
  count                = var.worker_instance_count
  ami                  = var.instance_ami_type
  instance_type        = var.instance_type_worker
  key_name             = "testing-dev-1"
  subnet_id            = aws_subnet.dev_subnet_private_1.id
  iam_instance_profile = data.aws_iam_instance_profile.s3-access-profile.name
  vpc_security_group_ids = [
    aws_security_group.kubernetes.id,
    aws_security_group.vpc_access.id,
    aws_security_group.etcd.id,
    aws_security_group.nat_gateway.id,
    aws_security_group.nfs.id,
  ]
  user_data = file("user-script-node.sh")
  tags = {
    "Name"                             = "worker${count.index + 1}"
    "Environment"                      = "Production"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
}
