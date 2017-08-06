data "template_file" "bucket_policy" {
  template = "${file("${path.module}/bucket_policy.json")}"

  vars {
    subdomain = "${var.subdomain}"
  }
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.subdomain}"
  acl = "public-read"
  policy = "${data.template_file.bucket_policy.rendered}"
}

resource "aws_s3_bucket_object" "upload_logo" {
  bucket = "${aws_s3_bucket.website_bucket.bucket}"
  key    = "origin/logo.png"
  source = "origin/logo.png"
}

data "template_file" "lambda_role_policy" {
  template = "${file("${path.module}/lambda_role_policy.json")}"
  vars {
    subdomain = "${var.subdomain}"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = "${data.template_file.lambda_role_policy.rendered}"
}

data "archive_file" "lambda_zip" {
  type          = "zip"
  source_file   = "/lambda/index.js"
  output_path   = "lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "test_lambda"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
}