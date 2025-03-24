packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

locals {
 timestamp = formatdate("YYYYMMDDhhmmss",timestamp())
}

variable "aws_region" {
    type = string
    default = "us-west-2"
}

variable "aws_instance_type" {
    type = string
    default = "t2.micro"
}

variable "aws_source_ami" {
    type = string
    default = "ami-00c257e12d6828491" # ubuntu 24.04
}

variable "s3_backup_bucket" {
    type = string
    default = "assignment-8-bucket-xiaole"  # your S3 bucket (set this) 
}

variable "mysql_user" {
    type = string
    sensitive = true        #set the user
}

variable "mysql_password" {
    type = string
    sensitive = true
}

variable "aws_access_key_id" {
    type = string
    sensitive = true
}

variable "aws_secret_access_key" {
    type = string
    sensitive = true
}


source "amazon-ebs" "mysql_ubuntu" {
  ami_name      = "ubuntu-mysql-${local.timestamp}"
  region        = "${var.aws_region}"
  instance_type = "${var.aws_instance_type}"
  source_ami    = "${var.aws_source_ami}"
  ssh_username  = "ubuntu"
  vpc_id        = "vpc-0d899d2c3d9eb482f"  # vpc required for non-default
  subnet_id     = "subnet-09a45aacb60195600" 
  security_group_ids = ["sg-0ef505b584420ddc0", "sg-0caec8950a52fb90f", "sg-0aeeba779dec4e250"]  
  associate_public_ip_address = true  # assign a public ip address, overrides default
  tags = {
    Environment = "Dev"
    Name        = "MySQL Server with Backup"
  }
}

build {
  sources = ["source.amazon-ebs.mysql_ubuntu"]

  provisioner "file" {
    source = "data/recommend.sql.gz"
    destination = "recommend.sql.gz"
  }

  provisioner "file" {
    source = "backup_mysql.sh"
    destination = "backup_mysql.sh"
  }

  provisioner "shell" {
    environment_vars = [ "MYSQL_USER=${var.mysql_user}", "MYSQL_PASS=${var.mysql_password}", "S3_BUCKET=${var.s3_backup_bucket}", "AWS_ACCESS_KEY_ID=${var.aws_access_key_id}", "AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}"]
    script = "scripts/setup-mysql.sh"
  }

}
