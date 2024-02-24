resource "aws_s3_bucket" "terraform_bucket" {
  bucket = var.bucket_name

}

resource "aws_s3_bucket_ownership_controls" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

### Allow public access
resource "aws_s3_bucket_public_access_block" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

### Configuring Website Pt 1
resource "aws_s3_bucket_acl" "terraform_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_bucket,
    aws_s3_bucket_public_access_block.terraform_bucket,
  ]

  bucket = aws_s3_bucket.terraform_bucket.id
  acl    = "public-read"
}

### Configuring Website Pt 2
resource "aws_s3_bucket_website_configuration" "terraform_bucket" {
  bucket = aws_s3_bucket.terraform_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

### Policy
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.terraform_bucket.id
  policy = data.aws_iam_policy_document.allow_access_from_another_account.json
}

data "aws_iam_policy_document" "allow_access_from_another_account" {
  statement {
    sid = "AddPerm"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.terraform_bucket.arn}/*",
    ]
  }
}

### Adding files to bucket
module "template_files" {
  source   = "hashicorp/dir/template"
  base_dir = "../build"
}

resource "aws_s3_object" "terraform_bucket" {
  bucket       = aws_s3_bucket.terraform_bucket.id
  for_each     = module.template_files.files
  key          = each.key
  content_type = each.value.content_type
  source       = each.value.source_path
  content      = each.value.content
}
