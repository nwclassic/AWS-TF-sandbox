provider "aws" {
    region = "us-west-2"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}

data "aws_ami" "latest_amazon_linux_image" {
    most_recent = "true"
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_instance" "my_app_server" {
    ami = data.aws_ami.latest_amazon_linux_image.id
    #instance_type = "t2.micro" Note: better way on the next line below.
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    #key_name = "M1 Air RSA" # This pulls the key from AWS that has been uploaded manually, it works but the following is better:
    key_name = aws_key_pair.ssh-key.key_name
#########################################################
    # 1 of 3 ways to configure an instance...
    # The following will run shell commands directly from TF, but there is not feedback
<<<<<<< HEAD
    # user-data passes the commends to AWS and AWS executes them
=======
>>>>>>> master
    #user_data = <<EOF
    #                		#!/bin/bash
    #               		sudo yum update -y && sudo yum install -y docker
    #                		sudo systemctl start docker
    #                		# adds ec2-user to docker group
    #                		sudo usermod -aG docker ec2-user
    #                		docker run -p 8080:80 nginx
    #			  EOF
#########################################################
    # 2 of 3 ways to configure instance...
<<<<<<< HEAD
    # This will run a shell script from a file by passing it to AWS and again AWS WILL RUN IT for you.
    #user_data = file("entry-script.sh")
#########################################################
    # 3 of 3 ways to configure an instance... Provisioner.
    # There are 3 types of provisioners:
        # 1. remote-exec with inline (script runs locally)
        # 2. remote-exec with script on ec2 server nd USE the provisioner "file to put the sript there first
        # 3.
    # Connection is required by provisioners as an explicit definition of how to connect via ssh.
    # self refers to the resource we are in, in this case, the aws_instance.my_app_server
=======
    # This will run a shell script from a file by passing it to AWS and AWS WILL RUN IT for you.
    #user_data = file("entry-script.sh")
#########################################################
    # 3 of 3 ways to configure an instance...
    # Connection is required by provisioner as an explicit definition of how to connect.
    # self refers to the resource we are in, the aws_instance.my_app_server
>>>>>>> master
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_location)
    }
<<<<<<< HEAD
    ########################################################
    ### Provisioner #1
    ########################################################

    # A provisioner in TF uses SSH to connect to an instance and then invokes a script.
=======
    # A provisioner invokes a script on a remote resource after it is created.
>>>>>>> master
    # This is an alternative to running a shell script
 #   provisioner "remote-exec" {
 #       inline = [
 #       "export ENV=dev",
 #       "mkdir newdir"
 #       ]
 #   }

    ########################################################
    ### Provisioner #2
    ########################################################
    // copy the .sh file to the remote hose
     provisioner "file" {
         source = "entry-script.sh"
         destination = "/home/ec2-user/entry-script-on-ec2.sh"
     }
    // remember that remote-exec will run this directly on the EC2 host so it must exist there!
    // The provisioner "file" will copy the file to the remote host for you
    // first change permissions to executable, then make a dir, and run script remotely
    // Note: docker run -d is required to make the docker image launch in EC2, i think... :-)
    provisioner "remote-exec" {
        inline = [
            "chmod +x /home/ec2-user/entry-script-on-ec2.sh",
            "mkdir newdir",
            "/home/ec2-user/entry-script-on-ec2.sh"
        ]
    }
<<<<<<< HEAD
=======
########################################################
>>>>>>> master

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server_key"
    #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDiSaTHCAKe8cx2SyUChI5c5dL3Bs/UmJ3Lz5/myHAZfE+9vXdkPh+kbJWIwK8q8lJxoGf8+qKVgBaU9MenUy9Z/u6HAaZLkjnJbMaZixynltwTheV3BHnOyenhJ2l8NtiCYQVazBfUP0XDjL1CnHFeo/nZxaGc9wsbAqU0VOcy6yrOwsXSjop9rB9GWgTm01us+HUXlr2lW9dvMosczS2hvBlVVfd40/OnyG1yZuYQ5ZIpF7gZJxaIAu/Xxm946Nse0lx/pQnAbxRmveIhn+g4QfZly450l7VS6XVkb/Rhze+ch9DbEg/6WUpp3x2xwP6NknDl+nZ9c5ALJoIAFU/QmMVMtdVgFiX2phBQMfXLQ4D6TE4PUR4T0Dp4QHKJnXr3BWBtoUjL2KGlDqKYi9BDK+vgINrHqhgLGmb7pxYGdCG+eOu97rw6HZtkP+iO9w9gYS/b+Jzrx0gsy6f7tmPLmjtd5pLEEt1oRdq7pvzKAi+EpKTwB9xpv0bm0bWwkOJBN729vgBFTq9MZMPeFyK4If8mc0wm039ySDPHPuJJwDpq2qsUFGeH4lvigqhXt4fPG7kFz4QrXttr2weRh6Hkbmsi4kXKb0Zt29XybR5QI5qleH4m8KrzJik6WS4rQHe/BIgRZFdpq3C8Nsy44so5Uox2NwCqp5sg54LzbrOUrQ== nwclassic@gmail.com"
    public_key = file(var.public_key_location)
}


/* This will output the id of the AMI that will be used */
output "aws_EC2_ami_id" {
    value = data.aws_ami.latest_amazon_linux_image.id
}
/* This will output the instance_type of the EC2 instance */
output "aws_EC2_instance_type" {
    value = aws_instance.my_app_server.instance_type
}
/* This will output the instance_id of the EC2 instance */
output "aws_EC2_instance_id" {
    value = aws_instance.my_app_server.id
}
/* This will output the public_ip_address of the EC2 instance */
output "aws_EC2_instance_public_ip" {
    value = aws_instance.my_app_server.public_ip
}
/* This will output the private_ip_address of the EC2 instance */
output "aws_EC2_instance_private_ip" {
    value = aws_instance.my_app_server.private_ip
}
