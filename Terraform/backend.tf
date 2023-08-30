terraform {
  backend "s3" {
    bucket         = "tf-ansible-backend"
    encrypt        = true
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-ansible-state-lock"
  }
}