# bbb_server_with_terraform
Deploy a BigBlueButton server on OVHcloud Public Cloud Instances with fully automated default configuration through Terraform

Use the following command line to launch deployment :

```bash
$ terraform apply \
  -var="ovh_region=GRA11" \                         # Default GRA7, make sure this region is available on your project
  -var="ovh_application_key=xxx" \                  # OVHcloud Application Key, use https://www.ovh.com/auth/createToken/ to generate one
  -var="ovh_application_secret=yyy" \               # OVHcloud Application Secret
  -var="ovh_consumer_key=zzz" \                     # OVHcloud Consumer Key
  -var="dns_domain=your.domain.tld" \               # OVHcloud DNS domain already available on your account
  -var="bbb_server_fqdn=bbb-server.subdomain" \     # BBB Server subdomain (without OVHcloud DNS domain)
  -var="bbb_server_image=Ubuntu 16.04" \            # Linux distribution used for deployement, default is Ubuntu 16.04 (currently only supported)
  -var="bbb_server_flavor=b2-7" \                   # Instance Flavor (CPU,RAM,Disk config), default is b2-7
  -var="bbb_letsencrypt_email=email@domain.tld" \   # Email address for Let's Encrypt to generate a valid SSL certificate for the host
  -var="keypair_name=keypair-with-terraform" \      # Keypair name stored in Openstack
  -var="public_key=~/.ssh/id_rsa.pub"               # Public Key used by Openstack
