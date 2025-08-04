variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}
variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
  default   = ["subnet-0c0bb5df2571165a9", "subnet-0cc2ddb32492bcc41"]
}

variable "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  default = "arn:aws:iam::607700977843:role/ecsTaskExecutionRole"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name (reference)"
  type        = string
  default     = "rutik-strapi-cluster-task11"
}

variable "container_name" {
  description = "Name of the container used in task definition"
  type        = string
  default     = "rutik-strapi"
}