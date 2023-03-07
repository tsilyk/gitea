// Gitea RDS MariaDB database
resource "aws_db_instance" "app_database" {
  identifier            = "${var.env_app}-mariadb"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "MariaDB"
  engine_version        = "10.6.10"
  instance_class        = "db.t2.micro"
  db_name               = "gitea"
  username              = "gitea"
  password              = var.rds_password
  //parameter_group_name = "default.mariadb10.6"
  skip_final_snapshot   = true
  apply_immediately     = true
  publicly_accessible   = false
  db_subnet_group_name  = aws_db_subnet_group.app_database.name
  parameter_group_name  = aws_db_parameter_group.app_database.name
  vpc_security_group_ids = [aws_security_group.app_database.id]
}

resource "aws_db_subnet_group" "app_database" {
  subnet_ids = var.database_subnets
  tags = {
    Name = "${var.env_app}-subnet-group"
  }
}

resource "aws_db_parameter_group" "app_database" {
  name   = "${var.env_app}-parameter-group"
  family = "mariadb10.6"
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
}

resource "aws_security_group" "app_database" {
  name   = "rds-${var.env_app}-db-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.sg_ingress_database_subnets
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
  }
}
