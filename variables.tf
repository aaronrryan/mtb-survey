variable "k8s_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "app_replicas" {
  description = "Number of application replicas"
  type        = number
  default     = 1
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "api_image" {
  description = "Docker image for the Flask API"
  type        = string
  default     = "aaronrryan/mtb-survey-api:latest"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "1.0.0"
} 