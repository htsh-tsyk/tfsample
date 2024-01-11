variable "secret_id" {
  description = "The secret ID. ex) google-ads-developer-credentials"
}

variable "secret_data" {
  description = "The secret data. ex) {\"client_id\":\"\",\"client_secret\":\"\",\"refresh_token\":\"\"}"
  type        = string
  sensitive   = true
}
