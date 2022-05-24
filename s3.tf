resource "aws_s3_bucket" "this" {
  bucket = "wordpress-uploads-bgn"
  force_destroy = true
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "AllowPublicRead",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::wordpress-uploads-bgn/*"
      }
    ]
  })
}
