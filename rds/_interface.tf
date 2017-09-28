#RDS variables
variable "dbuser" {
  default = "rootuser"
  description = "database user"
}

variable "dbpassword" {
  default = "rootpassword"
  description = "database password"
}

variable "dbengine" {
  default = "mysql"
  description = "database engine i.e. mysql/posgresql"
}

variable "dbengine_version" {
  default = "5.6.27"
  description = "database engine version"
}

variable "dbinstance_size" {
  default = "db.t2.micro"
}

#Outputs
output "db_user" {
  value = "${var.dbuser}"
}
output "db_password" {
  value = "${var.dbpassword}"
}
output "db_endpoint" {
  value = "${aws_db_instance.default.endpoint}"
}
output "db_address" {
  value = "${aws_db_instance.default.address}"
}
