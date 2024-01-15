terraform {
  backend "s3" {
    bucket         = "eks-terraform-bucket-west"
    key            = "backend/ToDo-App.tfstate"
    region         = "us-west-2"
    dynamodb_table = "eks-terraform-dynamo"
  }
}