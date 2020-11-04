output "creds" {
  description = "Credentials for pushing to ECR."
  value = {
    aws_access_key_id     = aws_iam_access_key.this.id
    aws_secret_access_key = aws_iam_access_key.this.secret
  }
}

output "location" {
  value = {
    image_tag       = "deploy"
    repository_arn  = aws_ecr_repository.this.arn
    repository_name = aws_ecr_repository.this.name
  }
}

output "repository_arns" {
  value = concat(
    [aws_ecr_repository.this.arn],
    [for repo in aws_ecr_repository.extra : repo.arn],
  )
}

output "repository_names" {
  value = concat(
    [aws_ecr_repository.this.name],
    [for repo in aws_ecr_repository.extra : repo.name],
  )
}

output "repository_urls" {
  value = concat(
    [aws_ecr_repository.this.repository_url],
    [for repo in aws_ecr_repository.extra : repo.repository_url],
  )
}
