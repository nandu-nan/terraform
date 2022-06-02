variable "reg" {
  default = "us-east-2"
} 

variable "vpcid" {
  default = "vpc-a45086cf"
}

variable "ec2type" {
  default = "t2.small"
}

variable "privsshkey" {
  default = "/root/.ssh/id_rsa"
}

variable "pubkey" {
  default = "/root/.ssh/id_rsa.pub"
}
