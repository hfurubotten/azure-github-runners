variable "github_org" {
  type = string
  description = "Name of the github organization hosting the custom runners"
}

variable "github_repo" {
  type = string
  description = "Name of the repository hosting the custom runners"
}

variable "runner_labels" {
  type = string
  description = "Labels that should trigger scaling of runners"

  default = "self-hosted,aca"
}
