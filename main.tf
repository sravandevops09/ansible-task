provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "backend" { #ubuntu.yaml NETADATA
  ami                    = "ami-0d176f79571d18a8f"
  instance_type          = "t3.micro" 
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-00318350619b1ae2b"]
  tags = {
    Name = "u21.local"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo hostnamectl set-hostname U21.local
  # netdata_conf="/etc/netdata/netdata.conf"
  # Path to netdata.conf
  # actual_ip=0.0.0.0
  # Use sed to replace the IP address in netdata.conf
  # sudo sed -i "s/bind socket to IP = .*$/bind socket to IP = $actual_ip/" "$netdata_conf"
EOF

}

resource "aws_instance" "frontend" { #amazon-playbook.yaml NGINX
  ami                    = "ami-0d176f79571d18a8f"
  instance_type          = "t3.micro"
  key_name               = "mumbai"
  vpc_security_group_ids = ["sg-07677724d1e159194"]
  tags = {
    Name = "c8.local"
  }
  user_data = <<-EOF
  #!/bin/bash
  # New hostname and IP address
  sudo hostnamectl set-hostname u21.local
  hostname=$(hostname)
  public_ip="$(curl -s https://api64.ipify.org?format=json | jq -r .ip)"

  # Path to /etc/hosts
  echo "${aws_instance.backend.public_ip} $hostname" | sudo tee -a /etc/hosts

EOF
depends_on = [aws_instance.backend]
}

resource "local_file" "inventory" {
  filename = "./inventory.yaml"
  content  = <<EOF
[frontend]
${aws_instance.frontend.public_ip}
[backend]
${aws_instance.backend.public_ip}
EOF
}

output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip
}

output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}
