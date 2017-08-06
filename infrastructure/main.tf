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