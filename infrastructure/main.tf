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

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.iam_for_lambda.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::__YOUR_BUCKET_NAME_HERE__/*"    
    }
  ]
}
EOF
}

data "archive_file" "lambda_zip" {
  type          = "zip"
  source_dir   = "/lambda"
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

resource "aws_lambda_permission" "with_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.test_lambda.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.website_bucket.arn}"
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${aws_s3_bucket.website_bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.test_lambda.arn}"
    events = ["s3:ObjectCreated:*"]
    filter_prefix = "origin/"
  }
}
