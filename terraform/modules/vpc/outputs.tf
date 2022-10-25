output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "dns_id" {
    value = aws_route53_zone.private_dns_zone.zone_id
}
