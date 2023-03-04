data "aws_route53_zone" "primary" {
  name         = var.zone_name
  private_zone = false
}

data "aws_elastic_beanstalk_hosted_zone" "current" {}

resource "aws_route53_record" "sub" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "${var.sub_zone}.${data.aws_route53_zone.primary.name}"
  type    = "A"
  alias {
    name                   = "${lower(var.cname)}"
    zone_id                = "${data.aws_elastic_beanstalk_hosted_zone.current.id}"
    evaluate_target_health = false
  }
}

