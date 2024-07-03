resource "aws_kms_key" "this" {
  description = "Generic Key for whole Demo"
  tags = merge(var.additional_tags,
    { Name = "kms-${var.projectidentifier}" },
  )
}

resource "aws_kms_alias" "a" {
  name          = "alias/kms-${var.projectidentifier}"
  target_key_id = aws_kms_key.this.key_id
}