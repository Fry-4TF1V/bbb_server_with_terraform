# bbb_server_with_terraform
Deploy a BigBlueButton server with fully automated default configuration through Terraform

Use the following command line to launch deployment :

$ terraform apply -auto-approve -var="ovh_region=GRA11" -var="dns_domain=your.domain.tld" -var="bbb_server_fqdn=bbb-server.subdomain" -var="bbb_letsencrypt_email=email@domain.tld" -var="ovh_application_key=xxx" -var="ovh_application_secret=yyy" -var="ovh_consumer_key=zzz"
