provider "ovh" {
  # Configuration options
  endpoint = "ovh-eu"
  application_key    = var.ovh_application_key
  application_secret = var.ovh_application_secret
  consumer_key       = var.ovh_consumer_key
}

resource random_password bbb_server_secret {
  length  = 64
  special = false
  upper   = false
  number  = true
}

# Import SSH Public Key
resource openstack_compute_keypair_v2 keypair {
  name       = var.keypair_name
  public_key = file(var.public_key)
  region     = var.ovh_region
}

# Define a Security group for this project
resource openstack_networking_secgroup_v2 bbb_secgroup {
  name        = "BigBlueButton_secgroup"
  description = "Security group for BigBlueButton"
  region      = var.ovh_region
}

# Define an Ingress policy for https
resource openstack_networking_secgroup_rule_v2 bbb_ingress_https {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

# Define an Ingress policy for http
resource openstack_networking_secgroup_rule_v2 bbb_ingress_http {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

# Define an Ingress policy for ssh
resource openstack_networking_secgroup_rule_v2 bbb_ingress_ssh {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

# Define an Ingress policy for rtp
resource openstack_networking_secgroup_rule_v2 bbb_ingress_rtp {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 16384
  port_range_max    = 32768
  remote_ip_prefix  = "0.0.0.0/0"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

# Define an Ingress policy for netdata
resource openstack_networking_secgroup_rule_v2 netdata_ingress_http {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 19999
  port_range_max    = 19999
  remote_ip_prefix  = "0.0.0.0/0"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

/* NOT REQUESTED AS IT IS CREATED BY DEFAULT IN SECGROUP
# Define an Egress policy for ipv4
resource openstack_networking_secgroup_rule_v2 bbb_egress_ipv4 {
  direction         = "egress"
  ethertype         = "IPv4"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}

# Define an Egress policy for ipv6
resource openstack_networking_secgroup_rule_v2 bbb_egress_ipv6 {
  direction         = "egress"
  ethertype         = "IPv6"
  region            = var.ovh_region
  security_group_id = openstack_networking_secgroup_v2.bbb_secgroup.id
}
*/
# Get Ext-Net network ID
data openstack_networking_network_v2 network_ext_net {
  name   = "Ext-Net"
  region = var.ovh_region
}

# Create Ext-Net network port
resource openstack_networking_port_v2 bbb_server_port {
  name                = "bbb_server_port"
  network_id          = data.openstack_networking_network_v2.network_ext_net.id
  admin_state_up      = "true"
  region              = var.ovh_region
  security_group_ids  = [openstack_networking_secgroup_v2.bbb_secgroup.id]
}

locals {
  # Retreive IP v4 of the created port
  bbb_ipv4 = [
    for ip in openstack_networking_port_v2.bbb_server_port.all_fixed_ips :
      ip
      if length(replace(ip, "/[[:alnum:]]+:[^,]+/", "")) > 0
    ][0]

  # Retreive IP v6 of the created port
  bbb_ipv6 = [
    for ip in openstack_networking_port_v2.bbb_server_port.all_fixed_ips :
      ip
      if length(replace(ip, "/[[:alnum:]]+\\.[^,]+/", "")) > 0
    ][0]
}

# Create an A (ipv4) record inside the DNS zone
resource ovh_domain_zone_record bbb_server_record_A {
  zone = var.dns_domain
  subdomain = var.bbb_server_fqdn
  fieldtype = "A"
  ttl = "60"
  target = local.bbb_ipv4
}

# Create an AAAA (ipv6) record inside the DNS zone
resource ovh_domain_zone_record bbb_server_record_AAAA {
  zone = var.dns_domain
  subdomain = var.bbb_server_fqdn
  fieldtype = "AAAA"
  ttl = "60"
  target = local.bbb_ipv6
}

# Create a BBB server on PCI
resource openstack_compute_instance_v2 bbb_server {
  count            = 1
  region           = var.ovh_region
  name             = "bbb"
  image_name       = var.bbb_server_image
  flavor_name      = var.bbb_server_flavor
  key_pair         = var.keypair_name
  network {
    port           = openstack_networking_port_v2.bbb_server_port.id
    access_network = true
  }
  user_data        = "#cloud-config\npackage_update: true\npackage_upgrade: true"
}

# Run the BBB install script inside the instance
resource null_resource install_bbb {
  triggers = {
     server_id =  openstack_compute_instance_v2.bbb_server[0].id
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      host     =  openstack_compute_instance_v2.bbb_server[0].access_ip_v4
    }

    inline = [
      #"sudo apt-get update -y && sudo apt-get upgrade -y",
      "cd /tmp/",
      # For Ubuntu 16.04
      #"wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | sudo bash -s -- -w -v xenial-22 -s ${var.bbb_server_fqdn}.${var.dns_domain} -e ${var.bbb_letsencrypt_email} -g",
      # For Ubuntu 18.04
      "wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | sudo bash -s -- -w -v bionic-230 -s ${var.bbb_server_fqdn}.${var.dns_domain} -e ${var.bbb_letsencrypt_email} -g",
      "sudo docker exec greenlight-v2 bundle exec rake admin:create",
      # An automatic user as been created on https://yoururl/b/ with the following credentials :
      # Email: admin@example.com
      # Password: administrator
      # REMEMBER TO change this default password ASAP
      "sudo bbb-conf --setsecret ${random_password.bbb_server_secret.result}",
      "sudo bbb-conf --restart",
      "sudo sed -i 's/BIGBLUEBUTTON_SECRET=.*/BIGBLUEBUTTON_SECRET=${random_password.bbb_server_secret.result}/g' ~/greenlight/.env",
      "sudo docker-compose -f ~/greenlight/docker-compose.yml up -d",
      # Install Netdata for monitoring purpose, available on port http://yoururl:19999
      "sudo ufw allow 19999/tcp",
      "wget -qO- https://my-netdata.io/kickstart.sh | sudo bash -s -- --dont-wait",
      "bbb-conf -secret",
    ]
  }
}
