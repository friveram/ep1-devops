#SetUp Inicial para utilizar terraform con DigitalOcean -------------
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}
variable "pvt_key" {}
variable "pub_key" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

//esta linea se usa solamente si la llave publica se crea de forma manual
//desde el navegador
/* data "digitalocean_ssh_key" "pubkeyssh" {
  name = "ep1devops"
} */

#Recursos ----------------------------------------------------------
#Recurso para establecer llave publica a las droplets
resource "digitalocean_ssh_key" "pubkeyssh" {
  name       = "publickey-ep1devops"
  public_key = file(var.pub_key)
}

#VPC principal de la infraestructura
resource "digitalocean_vpc" "vpc_main" {
  name     = "vpc1-ep1-devops"
  region   = "nyc1"
  ip_range = "172.16.16.0/24"
}

#Droplets
#Droplet con apache
resource "digitalocean_droplet" "web1" {
  image  = "ubuntu-18-04-x64"
  name   = "web1"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  vpc_uuid = digitalocean_vpc.vpc_main.id

  ssh_keys = [
      //se utiliza solo si se crea la llave publica desde el navegador
      //data.digitalocean_ssh_key.pubkeyssh.id
      resource.digitalocean_ssh_key.pubkeyssh.fingerprint
  ]

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' provision/apache-install.yml"
  }
}

#Droplet con nginx
resource "digitalocean_droplet" "web2" {
  image  = "ubuntu-18-04-x64"
  name   = "web2"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  vpc_uuid = digitalocean_vpc.vpc_main.id

  ssh_keys = [
      //se utiliza solo si se crea la llave publica desde el navegador
      //data.digitalocean_ssh_key.pubkeyssh.id
      resource.digitalocean_ssh_key.pubkeyssh.fingerprint
  ]

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]

    connection {
      host        = self.ipv4_address
      type        = "ssh"
      user        = "root"
      private_key = file(var.pvt_key)
    }
  }

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root -i '${self.ipv4_address},' --private-key ${var.pvt_key} -e 'pub_key=${var.pub_key}' provision/nginx-install.yml"
  }
}