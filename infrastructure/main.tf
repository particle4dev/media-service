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
      "Resource": "arn:aws:s3:::${var.subdomain}/*"
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

resource "aws_lambda_function" "image_processing_service" {
  filename         = "lambda_function.zip"
  function_name    = "image_processing_service"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs6.10"
}

resource "aws_lambda_permission" "with_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.image_processing_service.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.website_bucket.arn}"
}

resource "aws_s3_bucket_notification" "bucket_terraform_notification" {
  bucket = "${aws_s3_bucket.website_bucket.id}"
  lambda_function {
    lambda_function_arn = "${aws_lambda_function.image_processing_service.arn}"
    events = ["s3:ObjectCreated:*"]
    filter_prefix = "origin/"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name = "myapi"
  description = "Endpoint for aws_lambda function"
  binary_media_types = [
    "application/javascript",
    "application/json",
    "application/octet-stream",
    "application/xml",
    "font/eot",
    "font/opentype",
    "font/otf",
    "image/jpeg",
    "image/png",
    "image/svg+xml",
    "text/comma-separated-values",
    "text/css",
    "text/html",
    "text/javascript",
    "text/plain",
    "text/text",
    "text/xml"
  ]
}

resource "aws_api_gateway_resource" "image_proxy_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.image_proxy_resource.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  resource_id             = "${aws_api_gateway_resource.image_proxy_resource.id}"
  http_method             = "${aws_api_gateway_method.method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.image_processing_service.arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.image_processing_service.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}/image_proxy_resource"
  source_arn = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}

resource "aws_api_gateway_deployment" "test_env_deployment" {
  depends_on = [
    "aws_api_gateway_method.method",
    "aws_api_gateway_integration_response.api_demo_integration_response"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "test"

  variables = {
    "version" = "1.0.0"
  }
}

resource "aws_api_gateway_method_response" "200" {
    rest_api_id = "${aws_api_gateway_rest_api.api.id}"
    resource_id = "${aws_api_gateway_resource.image_proxy_resource.id}"
    http_method = "${aws_api_gateway_method.method.http_method}"
    status_code = "200"

    response_parameters = { "method.response.header.Content-Type" = true }
    response_models = {
      "image/png" = "Empty"
    }
}

resource "aws_api_gateway_integration_response" "api_demo_integration_response" {
  depends_on = [
    "aws_api_gateway_method.method",
    "aws_api_gateway_method_response.200"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.image_proxy_resource.id}"
  http_method = "${aws_api_gateway_method.method.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"

  response_parameters = {
    "method.response.header.Content-Type" = "'image/png'"
  }
  content_handling = "CONVERT_TO_BINARY"
}
