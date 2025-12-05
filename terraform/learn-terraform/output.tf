output "intance_hostname" {
    description = "Private DNS anem of the EC2 instance"
    value = aws_instance.app_server.private_dns
}