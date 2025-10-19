
data "aws_ami" "amazon_linux_2023" {
  provider    = aws.singapore
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "null_resource" "get_fargate_ip" {
  provisioner "local-exec" {
    command = <<-EOT
      sleep 30
      TASK_ARN=$(aws ecs list-tasks --region ap-northeast-1 --cluster ${aws_ecs_cluster.tokyo.name} --desired-status RUNNING --query 'taskArns[0]' --output text)
      aws ecs describe-tasks --region ap-northeast-1 --cluster ${aws_ecs_cluster.tokyo.name} --tasks $TASK_ARN --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text > ${path.module}/fargate_ip.txt
    EOT
  }

  depends_on = [aws_ecs_service.proxy]
}

data "local_file" "fargate_ip" {
  filename = "${path.module}/fargate_ip.txt"
  depends_on = [null_resource.get_fargate_ip]
}

resource "aws_instance" "private" {
  provider               = aws.singapore
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.singapore_private.id
  key_name               = aws_key_pair.singapore.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  user_data = templatefile("${path.module}/user_data/script_singapore.sh", {
    fargate_proxy_ip = trimspace(data.local_file.fargate_ip.content)
  })

  tags = {
    Name = "singapore-private-ec2"
  }

  depends_on = [null_resource.get_fargate_ip]
}
