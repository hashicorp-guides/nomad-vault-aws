# data backend


resource "aws_security_group" "rds" {
  name        = "database sg"
  vpc_id      = "${var.vpc_id}"
  description = "Security group for RDS"
  tags { Name = "nomad vault db" }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name        = "${var.name}"
  subnet_ids  = ["${split(",", var.subnet_ids)}"]
  description = "Subnet group for RDS"
  tags {
     Name = "DB subnet group"
  }
}

resource "aws_db_instance" "default" {
  name           = "initial_db"
  username       = "rootuser"
  password       = "rootpasswd"
  engine         = "mysql"
  engine_version = "5.6.17"

  multi_az                = "false"
  instance_class          = "db.t2.micro"
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
