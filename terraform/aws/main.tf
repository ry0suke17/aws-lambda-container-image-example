provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_ecr_repository" "hello_repo" {
  name = "hello"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "hello_func_container" {
  function_name = "hello-func-container"
  role          = aws_iam_role.iam_for_lambda.arn
  package_type = "Image"
  image_uri = "${aws_ecr_repository.hello_repo.repository_url}:latest"
}

resource "aws_lambda_function" "hello_func_zip" {
  function_name = "hello-func-zip"
  role          = aws_iam_role.iam_for_lambda.arn
  package_type = "Zip"
  filename = "bootstrap.zip"
  runtime = "provided.al2"
  handler = "bootstrap"
}