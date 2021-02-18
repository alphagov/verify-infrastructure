resource "aws_s3_bucket" "hub_key_rotation" {
  bucket = "govukverify-${var.environment}-hub-key-rotation"

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}