resource "aws_instance" "arango-master" {
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  key_name                    = "${var.key_pair}"
  # subnet_id                   = "${element(data.aws_subnet_ids.public.ids, count.index)}"
  subnet_id                   = "${element(data.aws_subnet_ids.private.ids, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.arangodb_security_group.id}"]
  connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${var.ssh_key_connection}")}"
      timeout = "5m"
  }

  provisioner "file" {
    source      = "arangodb.sh"
    destination = "/tmp/arangodb.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/arangodb.sh",
      "sudo /tmp/arangodb.sh"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo arangodb create jwt-secret --secret=jwtSecret",
      "sudo arangodb start --auth.jwt-secret=./jwtSecret",
      "sudo arangodb auth header --auth.jwt-secret=./jwtSecret",
      "sudo chmod 777 jwtSecret"
    ]
  }
  provisioner "local-exec" {    
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_key_connection} ec2-user@${aws_instance.arango-master.private_ip}:/home/ec2-user/jwtSecret ./"
  }
}

resource "aws_instance" "arango-slave" {
  count = "${var.instance_count_slave}"
  ami                         = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "${var.instance_type}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  key_name                    = "${var.key_pair}"
  subnet_id                   = "${element(data.aws_subnet_ids.private.ids, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.arangodb_security_group.id}"]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = "${file("${var.ssh_key_connection}")}"
    timeout = "5m"
  }
  
  provisioner "file" {
    source      = "arangodb.sh"
    destination = "/tmp/arangodb.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/arangodb.sh",
      "sudo /tmp/arangodb.sh"
    ]
  }
  provisioner "file" {
    source      = "jwtSecret"
    destination = "/tmp/jwtSecret"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo arangodb start --starter.join ${aws_instance.arango-master.private_ip} --auth.jwt-secret=/tmp/jwtSecret"
    ]
  }
}