module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  single_nat_gateway = true
  enable_nat_gateway = true
  enable_vpn_gateway = false


}


module "ec2-sg-bastion" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "assignment-bastion-sg"
  description = "Security Group for Bastion Host"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]

  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "All Internet Traffic"
    cidr_blocks = "0.0.0.0/0"
  }]
}


module "ec2-sg-private" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "assignment-app-sg"
  description = "Security Group for App Server"
  vpc_id      = module.vpc.vpc_id


   ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "All TCP traffic within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]


  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "All Internet Traffic"
    cidr_blocks = "0.0.0.0/0"
  }]
}



# Key Pair
resource "aws_key_pair" "my_key" {
  key_name   = "my-key-pair"
  public_key = file("/home/ubuntu/.ssh/id_ed25519")
}

# Bastion EC2 Instance (in Public Subnet)
resource "aws_instance" "bastion" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.medium"
  subnet_id              = module.vpc.public_subnets[0]
  monitoring             = true
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.ec2-sg-bastion.security_group_id]

  tags = {
    Name = "Bastion-Host"
  }
}

resource "aws_instance" "app_server" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.medium"
  subnet_id              = module.vpc.private_subnets[0]
  monitoring             = true
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.ec2-sg-private.security_group_id]

  tags = {
    Name = "App-Server"
  }
}

resource "aws_instance" "jenkins_server" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.medium"
  subnet_id              = module.vpc.private_subnets[1]
  monitoring             = true
  key_name               = aws_key_pair.my_key.key_name
  vpc_security_group_ids = [module.ec2-sg-private.security_group_id]

  tags = {
    Name = "Jenkins-Server"
  }
}
