resource "aws_db_instance" "self_service" {
  name         = "selfservice"
  engine       = "postgres"
  storage_type = "gp2"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  multi_az          = var.db_multi_az

  identifier = "${var.deployment}-${local.service}-db"
  username   = var.db_username

  # NOT THE REAL PASSWORD
  # The password is stored in SSM Parameter Store
  # This was done to avoid it being written to the tfstate file
  password   = "password"

  storage_encrypted = true

  vpc_security_group_ids = [aws_security_group.ingress_to_db.id]
  db_subnet_group_name   = aws_db_subnet_group.self_service_db_subnet_group.name

  maintenance_window      = "Tue:02:00-Tue:03:00"
  backup_window           = "03:00-03:30"
  backup_retention_period = var.db_backup_retention_period

  final_snapshot_identifier = "${var.deployment}-${local.service}-db-final-snapshot"

  deletion_protection = true

  iam_database_authentication_enabled = true
  apply_immediately                   = true

  lifecycle {
    prevent_destroy = true
    ignore_changes  = ["password"]
  }

  tags = {
      Name = "${var.deployment}-${local.service}-db"
   }
}

resource "aws_db_subnet_group" "self_service_db_subnet_group" {
  name       = "${var.deployment}-${local.service}-db-subnet-group"
  subnet_ids = data.terraform_remote_state.hub.outputs.internal_subnet_ids
}
