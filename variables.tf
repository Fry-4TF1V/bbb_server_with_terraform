variable ovh_region {
  type        = string
  description = "OVHcloud Public Cloud region used"
  default     = "GRA11"
}

variable ovh_application_key {
  type        = string
  description = "OVHcloud Application Key"
}

variable ovh_application_secret {
  type        = string
  description = "OVHcloud Application Secret"
}

variable ovh_consumer_key {
  type        = string
  description = "OVHcloud Consumer Key"
}

variable dns_domain {
  type        = string
  description = "OVHcloud DNS domain"
}

variable bbb_server_fqdn {
  type        = string
  description = "BBB Server subdomain (without OVHcloud DNS domain)"
}

variable bbb_server_image {
  type        = string
  description = "BBB Server Linux distribution"
  default     = "Ubuntu 18.04"
}

variable bbb_server_flavor {
  type        = string
  description = "BBB Server Flavor"
  default     = "b2-7"
}

variable bbb_letsencrypt_email {
  type        = string
  description = "Email address for Let's Encrypt to generate a valid SSL certificate for the host"
}

variable keypair_name {
  type        = string
  description = "Keypair name stored in Openstack"
  default     = "keypair-with-terraform"
}

variable public_key {
  type        = string
  description = "Public Key used by Openstack"
  default     = "~/.ssh/id_rsa.pub"
}
