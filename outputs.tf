# -----------------------------------------------------
# Outputs
# -----------------------------------------------------

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.server.id
}

output "public_ip" {
  description = "Elastic IP address of the server"
  value       = aws_eip.server.public_ip
}

output "public_dns" {
  description = "Public DNS of the Elastic IP"
  value       = aws_eip.server.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.server.public_ip}"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.server.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.amazon_linux.id
}
