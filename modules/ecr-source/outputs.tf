output "creds" {
  description = "Credentials for pushing to ECR."
  value = {
    aws_access_key_id     = aws_iam_access_key.this.id
    aws_secret_access_key = aws_iam_access_key.this.secret
  }
}

output "location" {
  description = "The ECR location which the pipeline will use as a source."
  value = {
    image_tag       = "deploy"
    repository_arn  = aws_ecr_repository.this.arn
    repository_name = aws_ecr_repository.this.name
  }
}

output "repository_arns" {
  description = "The ARNs of the created ECR repositories."
  value = concat(
    [aws_ecr_repository.this.arn],
    [for repo in aws_ecr_repository.extra : repo.arn],
  )
}

output "repository_names" {
  description = "The names of the created ECR repositories."
  value = concat(
    [aws_ecr_repository.this.name],
    [for repo in aws_ecr_repository.extra : repo.name],
  )
}

output "repository_urls" {
  description = "The URLs of the created ECR repositories."
  value = concat(
    [aws_ecr_repository.this.repository_url],
    [for repo in aws_ecr_repository.extra : repo.repository_url],
  )
}
