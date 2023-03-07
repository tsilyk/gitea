variable "cname" {
  description = "cname for route 53"
}
variable "zone_name" {
  description = "zone name if format <domain.com> for route 53"
}
variable "sub_zone" {
  description = "Subzone for domain (subdomain.<domain.com>) for route 53"
}
