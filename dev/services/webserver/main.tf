provider "aws" {
  region = "eu-west-1"
}


module "webservers"{
    source = "../../../modules/services/webservers"
}