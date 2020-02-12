resource "aws_route53_record" "www" {
  zone_id = "${var.zoneID}"
  name    = "arangodb.gruff.org"
  type    = "A"
  alias {
    name                   = "${aws_elb.elb-arangodb-cluster.dns_name}"
    zone_id                = "${aws_elb.elb-arangodb-cluster.zone_id}"
    evaluate_target_health = true
  }
}