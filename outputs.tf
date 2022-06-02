output "ubuntuip" {
  value = aws_instance.backend.public_ip
}
output "centosip" {
  value = aws_instance.frontend.public_ip
}
