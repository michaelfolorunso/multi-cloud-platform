resource "aws_db_subnet_group" "nexcloud" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
  }
}
# same postgres version as GCP side — keeping both clouds consistent
resource "aws_db_instance" "nexcloud_db" {
  identifier        = "${var.project_name}-db-${var.environment}"
  engine            = "postgres"
  engine_version    = "15.12"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "nexcloud"
  username = "nexcloud_app"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.nexcloud.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  # free tier doesn't allow backup retention — would set to 7 in production
  backup_retention_period = 0
  maintenance_window      = "Mon:03:00-Mon:04:00"

  tags = {
    Name        = "${var.project_name}-db-${var.environment}"
    Environment = var.environment
  }
}