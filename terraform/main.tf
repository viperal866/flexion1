provider "aws" {
    region = "us-east-1"
}

terraform {
    backend "s3" {}
}

resource "aws_vpc" "aws_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "aws_internet_gateway" {
    vpc_id = "${aws_vpc.aws_vpc.id}"
}

resource "aws_route" "aws_route" {
    route_table_id = "${aws_vpc.aws_vpc.default_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aws_internet_gateway.id}"
}

resource "aws_subnet" "aws_subnet1" {
    vpc_id     = "${aws_vpc.aws_vpc.id}"
    cidr_block = "10.0.0.0/17"
    availability_zone = "us-east-1a"
}

resource "aws_subnet" "aws_subnet2" {
    vpc_id     = "${aws_vpc.aws_vpc.id}"
    cidr_block = "10.0.128.0/17"
    availability_zone = "us-east-1b"
}


resource "aws_key_pair" "aws_key_pair" {
  key_name   = "aws_key_pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCYGaSz3got5Z1mz6lWX0uUkVCYrYEYcUpIDm0Qs1OHrIksm3S0SSLbNF3NNr+naaUOyE+nKZqhT3WL287plnM1E4eexVYHU0ogqUS33h+k9hwDE0hFOcIdQx75lnA5sEZ+u2uPAT5v9OBjsxs6dAdiDHLjYaqxia7vrljQzm37j4fvcjndILvMmkg23ut+cmOaKAahkebL0jO69BYo2pbJNlc5IHaMhbMr4qIwXz74ghM4vpMfozvfiegbyCFL3aUK8YcZX6PlGa2neCLkpBUJErvgvxnDGdcAuifkwN2Z5CqiUrtAqvuqgTwyL/K68faAOh7tXnxGVznydldi+qTP key"
}

resource "aws_security_group" "aws_security_group" {
  name        = "main"
  description = "main"
  vpc_id      = "${aws_vpc.aws_vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "aws_instance" {
    depends_on = ["aws_db_instance.aws_db_instance"]
    subnet_id     = "${aws_subnet.aws_subnet1.id}"
  ami           = "ami-2f442839"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.aws_security_group.id}"]
  key_name ="${aws_key_pair.aws_key_pair.id}"
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y install postgresql postgresql-contrib",
      "echo \"${element(split(":", aws_db_instance.aws_db_instance.endpoint), 0)}:${element(split(":", aws_db_instance.aws_db_instance.endpoint), 1)}:appdatabase:DBUSER:DBPASSWORD\" >> /home/ubuntu/.pgpass",
      "chmod 600 /home/ubuntu/.pgpass",
      "psql -h ${element(split(":", aws_db_instance.aws_db_instance.endpoint), 0)} -p ${element(split(":", aws_db_instance.aws_db_instance.endpoint), 1)} -U DBUSER -d appdatabase -c \"CREATE TABLE app (data VARCHAR(50));\"",
      "psql -h ${element(split(":", aws_db_instance.aws_db_instance.endpoint), 0)} -p ${element(split(":", aws_db_instance.aws_db_instance.endpoint), 1)} -U DBUSER -d appdatabase -c \"INSERT INTO app (data) VALUES ('CHANGEME');\"",
      "(echo audit && echo audit) | sudo passwd", # Allow auditors
    ]

    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file("ssh/id_rsa")}"
    }
  }
  provisioner "local-exec" {
    command = "env ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vvvv -T 60 -i \"${self.public_dns},\" ../ansible/playbook.yml -u ubuntu --private-key=ssh/id_rsa --extra-vars '{\"appl_cidrs\":[\"${aws_subnet.aws_subnet1.cidr_block}\",\"${aws_subnet.aws_subnet2.cidr_block}\"]}' --extra-vars env=prod --extra-vars dbhost=${aws_db_instance.aws_db_instance.endpoint}"
  }
}

resource "aws_db_subnet_group" "aws_db_subnet_group" {
  name       = "main"
  subnet_ids = ["${aws_subnet.aws_subnet1.id}", "${aws_subnet.aws_subnet2.id}"]
}

resource "aws_db_instance" "aws_db_instance" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "9.4.14"
  instance_class       = "db.t2.micro"
  name                 = "appdatabase"
  username             = "DBUSER"
  password             = "DBPASSWORD"
  db_subnet_group_name = "${aws_db_subnet_group.aws_db_subnet_group.id}"
  publicly_accessible = true
  vpc_security_group_ids = ["${aws_security_group.aws_security_group.id}"]
  skip_final_snapshot = true
}

resource "aws_route53_zone" "aws_route53_zone" {
  name = "coolapp.com"
}

resource "aws_route53_record" "www" {
  zone_id = "${aws_route53_zone.aws_route53_zone.zone_id}"
  name    = "coolapp.com"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.aws_instance.public_ip}"]
}
