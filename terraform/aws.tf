variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_security_group_id" {
  type = string
}

variable "aws_key_name" {
  type = string
}

provider "aws" {
  region = "eu-west-3"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_instance" "demo" {
  instance_type = "t2.small"
  ami = "ami-2cf54551"
  vpc_security_group_ids = [var.aws_security_group_id]
  key_name = var.aws_key_name

  provisioner "remote-exec" {
    inline = [
      #install SW
      "sudo yum install -y httpd git postgresql-server postgresql-contrib",

      #get dart-sdk
      "cd /tmp",
      "wget https://storage.googleapis.com/dart-archive/channels/stable/release/2.7.1/sdk/dartsdk-linux-x64-release.zip",
      "unzip dartsdk-linux-x64-release.zip",
      "sudo mv dart-sdk/ /opt/",
      "export PATH=$PATH:/opt/dart-sdk/bin/",

      #build webdev tool
      "/opt/dart-sdk/bin/pub global activate webdev",
      "export PATH=$PATH:~/.pub-cache/bin/",

      #build app
      "git clone https://github.com/pe-pan/operam",
      "sudo sed -i -- 's|4041|8080|g' $(find /tmp/operam/bin -maxdepth 1 -type f)",
      "sudo sed -i -- 's|http://localhost:8080|http://${aws_instance.demo.public_ip}|g' $(find /tmp/operam/ -maxdepth 2 -type f)",
      "sudo sed -i -- 's|http://localhost:4041|http://${aws_instance.demo.public_ip}:8080|g' $(find /tmp/operam/ -maxdepth 2 -type f)",
      "cd operam",
      "pub get",
      "webdev build",
      "sudo mv build/* /var/www/html/",
      "sudo mv /tmp/operam/ /opt",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }

  #setup DB
  provisioner "remote-exec" {
    script = "setup-psql.sh"
  }

  #copy secret keys to the app
  provisioner "file" {
    source      = "secrets.json"
    destination = "/tmp/secrets.json"
  }

   #start the app
   provisioner "remote-exec" {
     inline = [
       "cd /opt/operam/bin/",
       "nohup  /opt/dart-sdk/bin/dart --enable-asserts main.dart /tmp/secrets.json > /tmp/dart.log &",
       "sleep 2"  #FMI, see https://stackoverflow.com/questions/36207752/how-can-i-start-a-remote-service-using-terraform-provisioning
     ]
   }

  connection {
      timeout = "5m"
      user = "ec2-user"
      private_key="${file("private_key.pem")}"
	  host = self.public_ip
  }

}
output "ip" {
        value = "${aws_instance.demo.public_ip}"
}

output "url" {
        value = "http://${aws_instance.demo.public_ip}/register_phone.html"
}