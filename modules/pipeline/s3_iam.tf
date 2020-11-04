data "aws_iam_policy_document" "pipeline_bucket" {
  statement {
    sid       = "AllowAccessFromTargetAccounts"
    actions   = ["s3:GetObject*"]
    resources = ["${aws_s3_bucket.pipeline.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [for target in var.targets : target.assume_role.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "pipeline" {
  bucket = aws_s3_bucket.pipeline.bucket
  policy = data.aws_iam_policy_document.pipeline_bucket.json
}
