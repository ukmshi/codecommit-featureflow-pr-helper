variable "repository_names" {
  type        = list(string)
  description = "List of CodeCommit repository names"
  default     = []
}

variable "staging_branch" {
  type        = string
  description = "Name of the staging branch"
  default     = "staging"
}

variable "master_branch" {
  type        = string
  description = "Name of the master branch"
  default     = "master"
}

variable "identifier" {
  type        = string
  description = "A unique identifier to prepend to resource names"
  default     = ""
}

variable "log_retention_in_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group"
  default     = 14
}
