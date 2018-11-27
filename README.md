# DC/OS Terraform Infrastructure Module with Ansible Bridge Module (AWS)

The following is a quick demo of how to use DC/OS Terraform Infrastructure Module with DC/OS Terraform Ansible Bridge Module on AWS to create a DC/OS Open cluster on AWS. This is being made available for users that wish to use Ansible as a management tool for installing and maintaing DC/OS instead of the default DC/OS Core. The Infrastructure Module is responsible for standing up the Infrastructure pieces necessary to have a running DC/OS Cluster while the Ansible Bridge module is used to create a `hosts` file to run your ansible roles against. 

In this example Ansible Roles are being supplied from the `dcos-ansible` repo just to provide users with a working example. Please feel free to use you own Ansible Code here as a replacement. 

We will setup a small Open cluster in `us-east-1` with 1 Bootstrap, 1 Master, 1 Private Agent and 1 Public Agent. Please feel free to adjust the variables in the `main.tf` to fit your needs. 

## Requirements

This is a quick and dirty example, so for more information, please read the docs pertaining to both of the Terraform Modules as well as the `dcos-ansible` repo for customizied usage options:

- DC/OS Terraform Infrastructure Module
- DC/OS Terraform Ansible Bridge
- DC/OS Ansible

## Usage

1) Set specifics for variables in `main.tf` such as number of instances, ami, cluster name and key. 

2) Also set the Version of DC/OS (version]) and the URL (download) in the `vars_file` resource. You can get this info from https://dcos.io/releases/.

3) Init, Plan and Apply Terraform.
```
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

When Terraform completes you will see you will see output information pertaining to your instances as well as `./hosts` and `./group_vars/all/dcos.yaml` files for Ansible inventory and variables. Terraform will automatically fill in the needed information.

4) Run the playbook to install DC/OS.
```
ansible-playbook install.yml
```

Once Ansible completes you will be able to access your cluster via the LB created from the Infrastructure Module:
``` bash
aws elb describe-load-balancers --load-balancer-name ${cluster_name} | grep DNSName
```

Copy and past into your web browser.


## Tested OS and Mesosphere DC/OS versions

* CentOS 7
* DC/OS 1.12, both open as well as enterprise version

## License
[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)

## Author Information
This role was created by team SRE @ Mesosphere and others in 2018, based on multiple internal tools and non-public Ansible roles that have been developed internally over the years.
