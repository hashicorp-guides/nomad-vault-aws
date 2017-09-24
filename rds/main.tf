terraform {
  required_version = ">= 0.9.3"
}

data "terraform_remote_state" "vault" {
  backend = "local"
  config {
    path = "${path.module}/../vault/vault.tfstate"
  }
}

resource "aws_security_group" "rds" {
  name        = "database sg"
  vpc_id      = "${data.terraform_remote_state.vault.vpc_id}"
  description = "Security group for RDS"
  tags { Name = "nomad vault db" }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${data.terraform_remote_state.vault.vpc_cidr}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "nomad vault subnet group"
  #subnet_ids  = ["${data.terraform_remote_state.vault.subnet_public_ids.0}"]
  subnet_ids  = ["${data.terraform_remote_state.vault.subnet_public_ids}"]
  description = "Subnet group for RDS"
  tags {
     Name = "DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  name           = "demo_db"
  username       = "${var.dbuser}"
  password       = "${var.dbpassword}"
  engine         = "${var.dbengine}"
  engine_version = "${var.dbengine_version}"

  multi_az                = "false"
  instance_class          = "${var.dbinstance_size}"
  allocated_storage       = "100"
  storage_type            = "gp2"
  apply_immediately       = "true"
  publicly_accessible     = "false"
  skip_final_snapshot       = true

  vpc_security_group_ids    = ["${aws_security_group.rds.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.default.id}"
}

provider "mysql" {
  endpoint = "${aws_db_instance.default.endpoint}"
  username = "${aws_db_instance.default.username}"
  password = "${aws_db_instance.default.password}"
}

resource "mysql_database" "app" {
  name = "app"
}
