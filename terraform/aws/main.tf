provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_ecr_repository" "hello_repo" {
  name = "hello"
}
