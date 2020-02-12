resource "aws_elb" "elb-arangodb-cluster" {
  name                = "elb-arangodb-cluster"
  security_groups     = ["${aws_security_group.elbsg.id}"]
  subnets             = ["${data.aws_subnet_ids.private.ids}"]
  internal            = true
  listener = [
    {
      instance_port      = 8529
      instance_protocol  = "http"
      lb_port            = 443
      lb_protocol        = "https"
      ssl_certificate_id = "${var.ssl_arn}" # https://github.com/terraform-aws-modules/terraform-aws-elb/issues/5
    },
  ]
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 3
    target              = "HTTP:8529/_db/_system/_admin/aardvark/index.html"
    interval            = 60
  }
  instances             = ["${aws_instance.arango-master.id}", ["${aws_instance.arango-slave.*.id}"]]
  cross_zone_load_balancing   = true
}