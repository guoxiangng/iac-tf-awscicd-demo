variable "additional_tags" {
  default     = { project = "lzdemo" }
  description = "Additional resource tags"
  type        = map(string)

}

variable "projectidentifier" {
  default     = "lzdemo"
  description = "Project Identifier for which this Infra Provisioning Automation will be used"
  type        = string
}