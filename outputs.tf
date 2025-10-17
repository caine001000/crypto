output "tokyo_proxy_public_ip" {
  description = "Tokyo proxy public IP (egress IP)"
  value       = aws_instance.tokyo_proxy.public_ip
}

output "tokyo_proxy_private_ip" {
  description = "Tokyo proxy private IP"
  value       = aws_instance.tokyo_proxy.private_ip
}

output "singapore_ec2_public_ip" {
  description = "Singapore EC2 public IP"
  value       = aws_instance.singapore.public_ip
}

output "singapore_ec2_private_ip" {
  description = "Singapore EC2 private IP"
  value       = aws_instance.singapore.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to Singapore EC2"
  value       = "ssh -i singapore-key.pem ubuntu@${aws_instance.singapore.public_ip}"
}