output "jenkins_ssh_key" {
  value = tls_private_key.ssh_key.private_key_pem
}

output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}