/*
resource "aws_secretsmanager_secret" "mydb_secret" {
  name        = "my-db-secret"
  description = "My Database Secret"
}

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    
  })
}
*/