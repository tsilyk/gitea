output "efs_arn" {
  value       = aws_efs_file_system.this.arn
  description = "EFS ARN"
}

output "efs_id" {
  value       = aws_efs_file_system.this.id
  description = "EFS ID"
}

output "efs_ap_id" {
  value       = aws_efs_access_point.this.id
  description = "EFS AP ID"
}

output "dns_name" {
  value       = aws_efs_file_system.this.dns_name
  description = "EFS DNS name"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "EFS Security Group ID"
}

output "security_group_arn" {
  value       = aws_security_group.this.arn
  description = "EFS Security Group ARN"
}

output "security_group_name" {
  value       = aws_security_group.this.name
  description = "EFS Security Group name"
}

output "mount_target_ids" {
  value       = coalescelist(aws_efs_mount_target.this.*.id, [""])
  description = "List of EFS mount target IDs (one per Availability Zone)"
}

output "efs_access_point_id" {
  value       = aws_efs_access_point.this.id
  description = "EFS AP ID"
}
