variable "region" {
  description = "The AWS region to deploy into."
  default     = "us-west-2"
}

variable "project_name" {
  description = "The project name. Used to name AWS resources"
  default     = "udacity-devops-project-3"
}

variable "ssh_allowed_cidr" {
  description = "IP to allow SSH access from"
}