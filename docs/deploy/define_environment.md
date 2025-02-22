# Define the environment
An **az-hop** environment is defined in the `config.yml` configuration file. Before starting, use the `config.tpl.yml` template to build a configuration file that fill your needs.
Here is a template for building such configuration file.

```yml
---
---
# azure location name as returned by the command : az account list-locations -o table
location: westeurope
# Name of the resource group to create all resources
resource_group: azhop
# If using an existing resource group set to true. Default is false
# When using an existing resource group make sure the location match the one of the existing resource group
use_existing_rg: false
# Additional tags to be added on the Resource Group
tags:
  env: dev
  project: azhop
# Define an Azure Netapp Files (ANF) account, single pool and volume
# If not present, assume that there is an existing NFS share for the users home directory
anf:
  # Size of the ANF pool and unique volume (min: 4TB, max: 100TB)
  homefs_size_tb: 4
  # Service level of the ANF volume, can be: Standard, Premium, Ultra
  homefs_service_level: Standard
  # dual protocol
  dual_protocol: false # true to enable SMB support. false by default

mounts:
  # mount settings for the user home directory
  home:
    mountpoint: /anfhome # /sharedhome for example
    server: '{{anf_home_ip}}' # Specify an existing NFS server name or IP, when using the ANF built in use '{{anf_home_ip}}'
    export: '{{anf_home_path}}' # Specify an existing NFS export directory, when using the ANF built in use '{{anf_home_path}}'

# name of the admin account
admin_user: hpcadmin
# Object ID to grant key vault read access
key_vault_readers: #<object_id>
# Network
network:
  # Create Network and Application Security Rules, true by default, false when using an existing VNET if not specified
  create_nsg: true
  vnet:
    name: hpcvnet # Optional - default to hpcvnet
    id: # If a vnet id is set then no network will be created and the provided vnet will be used
    address_space: "10.0.0.0/16" # Optional - default to "10.0.0.0/16"
    # When using an existing VNET, only the subnet names will be used and not the adress_prefixes
    subnets: # all subnets are optionals
    # name values can be used to rename the default to specific names, address_prefixes to change the IP ranges to be used
    # All values below are the default values
      frontend: 
        name: frontend
        address_prefixes: "10.0.0.0/24"
        create: true # create the subnet if true. default to true when not specified, default to false if using an existing VNET when not specified
      admin:
        name: admin
        address_prefixes: "10.0.1.0/24"
        create: true
      netapp:
        name: netapp
        address_prefixes: "10.0.2.0/24"
        create: true
      ad:
        name: ad
        address_prefixes: "10.0.3.0/28"
        create: true
      # Bastion and Gateway subnets are optional and can be added if a Bastion or a VPN need to be created in the environment
      # bastion: # Bastion subnet name is always fixed to AzureBastionSubnet
      #   address_prefixes: "10.0.4.0/27" # CIDR minimal range must be /27
      #   create: true
      # gateway: # Gateway subnet name is always fixed to GatewaySubnet
      #   address_prefixes: "10.0.4.32/27" # Recommendation is to use /27 or /28 network
      #   create: true
      compute:
        name: compute
        address_prefixes: "10.0.16.0/20"
        create: true
  # Specify the Application Security Groups mapping if already existing
# asg:
#   resource_group: # name of the resource group containing the ASG. Default to the resource group containing azhop resources
#   names: # list of ASG names mapping to the one defined in az-hop
#     asg-ssh: asg-ssh
#     asg-rdp: asg-rdp
#     asg-jumpbox: asg-jumpbox
#     asg-ad: asg-ad
#     asg-ad-client: asg-ad-client
#     asg-lustre: asg-lustre
#     asg-lustre-client: asg-lustre-client
#     asg-pbs: asg-pbs
#     asg-pbs-client: asg-pbs-client
#     asg-cyclecloud: asg-cyclecloud
#     asg-cyclecloud-client: asg-cyclecloud-client
#     asg-nfs-client: asg-nfs-client
#     asg-telegraf: asg-telegraf
#     asg-grafana: asg-grafana
#     asg-robinhood: asg-robinhood
#     asg-ondemand: asg-ondemand
#     asg-deployer: asg-deployer
#     asg-guacamole: asg-guacamole
    
#  peering: # This list is optional, and can be used to create VNet Peerings in the same subscription.
#    - vnet_name: #"VNET Name to Peer to"
#      vnet_resource_group: #"Resource Group of the VNET to peer to"

# Specify DNS forwarders available in the network
# dns:
#   forwarders:
#     - { name: foo.com, ips: "10.2.0.4, 10.2.0.5" }

# When working in a locked down network, uncomment and fill out this section
locked_down_network:
  enforce: false
#   grant_access_from: [a.b.c.d] # Array of CIDR to grant access from, see https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security?tabs=azure-portal#grant-access-from-an-internet-ip-range
  public_ip: true # Enable public IP creation for Jumpbox, OnDemand and create images. Default to true

# Base image configuration. Can be either an image reference or an image_id from the image registry or a custom managed image
linux_base_image: "OpenLogic:CentOS:7_9-gen2:latest" # publisher:offer:sku:version or image_id
linux_base_plan: # linux image plan if required, format is publisher:product:name
windows_base_image: "MicrosoftWindowsServer:WindowsServer:2019-Datacenter-smalldisk:latest" # publisher:offer:sku:version or image_id
lustre_base_image: "azhpc:azurehpc-lustre:azurehpc-lustre-2_12:latest"
# The lustre plan to use. Only needed when using the default lustre image from the marketplace. use "::" for an empty plan
lustre_base_plan: "azhpc:azurehpc-lustre:azurehpc-lustre-2_12" # publisher:product:name

# Jumpbox VM configuration
jumpbox:
  vm_size: Standard_B2ms
  # SSH port under which the jumpbox SSH server listens on the public IP. Default to 22
  # Change this to, e.g., 2222, if security policies (like "zero trust") in your tenant automatically block access to port 22 from the internet
  #ssh_port: 2222
# Active directory VM configuration
ad:
  vm_size: Standard_B2ms
  hybrid_benefit: false # Enable hybrid benefit for AD, default to false
  high_availability : false # Build AD in High Availability mode (2 Domain Controlers) - default to false
# On demand VM configuration
ondemand:
  vm_size: Standard_D4s_v5
  #fqdn: azhop.foo.com # When provided it will be used for the certificate server name
  generate_certificate: true # Generate an SSL certificate for the OnDemand portal. Default to true
# Grafana VM configuration
grafana:
  vm_size: Standard_B2ms
# Guacamole VM configuration
guacamole:
  vm_size: Standard_B2ms
# Scheduler VM configuration
scheduler:
  vm_size: Standard_B2ms
# CycleCloud VM configuration
cyclecloud:
  vm_size: Standard_B2ms
  # version: 8.2.1-1733 # to specify a specific version, see https://packages.microsoft.com/yumrepos/cyclecloud/

# Lustre cluster is optional and can be used to create a Lustre cluster in the environment.
# Comment the whole section if you don't want to create a Lustre cluster.
lustre:
  rbh_sku: "Standard_D8d_v4"
  mds_sku: "Standard_D8d_v4"
  oss_sku: "Standard_D32d_v4"
  oss_count: 2
  hsm_max_requests: 8
  mdt_device: "/dev/sdb"
  ost_device: "/dev/sdb"
  hsm:
    # optional to use existing storage for the archive
    # if not included it will use the azhop storage account that is created
    storage_account: #existing_storage_account_name
    storage_container: #only_used_with_existing_storage_account
# List of users to be created on this environment
users:
  # name: username - must be less than 20 characters
  # uid: uniqueid
  # shell: /bin/bash # default to /bin/bash
  # home: /anfhome/<user_name> # default to /homedir_mountpoint/user_name
  # groups: list of groups the user belongs to
  - { name: clusteradmin, uid: 10001, groups: [5001, 6000, 6001] }
  - { name: clusteruser, uid: 10002 }
  - { name: user1, uid: 10003, groups: [6000] }
  - { name: user2, uid: 10004, groups: [6001] }

usergroups:
# These groups can’t be changed
  - name: Domain Users # All users will be added to this one by default
    gid: 5000
  - name: az-hop-admins
    gid: 5001
    description: "For users with azhop admin privileges"
  - name: az-hop-localadmins
    gid: 5002
    description: "For users with sudo right or local admin right on nodes"
# For custom groups use gid >= 6000
  - name: project1 # For project1 users
    gid: 6000
  - name: project2 # For project2 users
    gid: 6001

# Enable cvmfs-eessi - disabled by default
# cvmfs_eessi:
#   enabled: true

# scheduler to be installed and configured (openpbs, slurm)
queue_manager: openpbs

# Specific SLURM configuration
slurm:
  # Enable SLURM accounting, this will create a SLURM accounting database in a managed MySQL server instance
  accounting_enabled: false
  # Enable container support for SLURM using Enroot/Pyxis
  enroot_enabled: false

# Authentication configuration for accessing the az-hop portal
# Default is basic authentication. For oidc authentication you have to specify the following values
# The OIDCClient secret need to be stored as a secret named <oidc-client-id>-password in the keyvault used by az-hop
authentication:
  httpd_auth: basic # oidc or basic
  # User mapping https://osc.github.io/ood-documentation/latest/reference/files/ood-portal-yml.html#ood-portal-generator-user-map-match
  # You can specify either a map_match or a user_map_cmd
  # Domain users are mapped to az-hop users with the same name and without the domain name
  # user_map_match: '^([^@]+)@mydomain.foo$'
  # If using a custom mapping script, update it from the ./playbooks/files directory before running the playbook
  # user_map_cmd: /opt/ood/ood_auth_map/bin/custom_mapping.sh
  # ood_auth_openidc:
  #   OIDCProviderMetadataURL: # for AAD use 'https://sts.windows.net/{{tenant_id}}/.well-known/openid-configuration'
  #   OIDCClientID: 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
  #   OIDCRemoteUserClaim: # for AAD use 'upn'
  #   OIDCScope: # for AAD use 'openid profile email groups'
  #   OIDCPassIDTokenAs: # for AAD use 'serialized'
  #   OIDCPassRefreshToken: # for AAD use 'On'
  #   OIDCPassClaimsAs: # for AAD use 'environment'

# List of images to be defined
images:
  # - name: image_definition_name # Should match the packer configuration file name, one per packer file
  #   publisher: azhop
  #   offer: CentOS
  #   sku: 7_9-gen2
  #   hyper_v: V2 # V1 or V2 (V1 is the default)
  #   os_type: Linux # Linux or Windows
  #   version: 7.9 # Version of the image to create the image definition in SIG. Pattern is major.minor where minor is mandatory
# Pre-defined images
  - name: azhop-almalinux85-v2-rdma-gpgpu
    publisher: azhop
    offer: almalinux
    sku: 8_5-hpc-gen2
    hyper_v: V2
    os_type: Linux
    version: 8.5
  - name: azhop-centos79-v2-rdma-gpgpu
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2
    hyper_v: V2
    os_type: Linux
    version: 7.9
  # Image definition when using a custom image to build compute nodes images
  - name: azhop-centos79-v2-rdma-ci
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2-ci
    hyper_v: V2
    os_type: Linux
    version: 7.9
  # Image definition when using a custom image to build remote viz nodes images
  - name: azhop-centos79-desktop3d-ci
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2-desktop3d-ci
    hyper_v: V2
    os_type: Linux
    version: 7.9
  - name: azhop-centos79-desktop3d
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2-desktop3d
    hyper_v: V2
    os_type: Linux
    version: 7.9
  - name: azhop-ubuntu18.04
    publisher: azhop
    offer: Ubuntu
    sku: 10_04
    hyper_v: V2
    os_type: Linux
    version: 18.04
  - name: azhop-win10
    publisher: azhop
    offer: Windows-10
    sku: 21h1-pron
    hyper_v: V1
    os_type: Windows
    version: 10.19043
  # Base image when building your own HPC image and not using the HPC marketplace images
  - name: base-centos79-v2-rdma
    publisher: azhop
    offer: CentOS
    sku: 7.9-gen2-rdma-nogpu
    hyper_v: V2
    os_type: Linux
    version: 7.9

# List of queues (node arays in Cycle) to be defined
queues:
  - name: execute # name of the Cycle Cloud node array
    # Azure VM Instance type
    vm_size: Standard_F2s_v2
    # maximum number of cores that can be instanciated
    max_core_count: 1024
    # marketplace image name or custom image id
#    image: OpenLogic:CentOS-HPC:7_9-gen2:latest
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    # Image plan specification (when needed for the image). Terms must be accepted prior to deployment
#    plan: publisher:product:name
    # Set to true if AccelNet need to be enabled. false is the default value
    EnableAcceleratedNetworking: false
    # spot instance support. Default is false
    spot: false
    # Set to false to disable creation of placement groups (for SLURM only). Default is true
    ColocateNodes: false
  - name: hc44rs
    vm_size: Standard_HC44rs
    max_core_count: 440
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    spot: true
  - name: hb120v2
    vm_size: Standard_HB120rs_v2
    max_core_count: 1200
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    spot: true
  - name: hb120v3
    vm_size: Standard_HB120rs_v3
    max_core_count: 1200
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-v2-rdma-gpgpu/latest
    spot: true
    # Queue dedicated to GPU remote viz nodes. This name is fixed and can't be changed
  - name: viz3d
    vm_size: Standard_NV12s_v3
    max_core_count: 48
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-desktop3d/latest
    ColocateNodes: false
    spot: false
    # Queue dedicated to share GPU remote viz nodes. This name is fixed and can't be changed
  - name: largeviz3d
    vm_size: Standard_NV48s_v3
    max_core_count: 96
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-desktop3d/latest
    ColocateNodes: false
    spot: false
    # Queue dedicated to non GPU remote viz nodes. This name is fixed and can't be changed
  - name: viz
    vm_size: Standard_D8s_v5
    max_core_count: 200
    image: /subscriptions/{{subscription_id}}/resourceGroups/{{resource_group}}/providers/Microsoft.Compute/galleries/{{sig_name}}/images/azhop-centos79-desktop3d/latest
    ColocateNodes: false
    spot: false

# Remote Visualization definitions
enable_remote_winviz: false # Set to true to enable windows remote visualization

remoteviz:
  - name: winviz # This name is fixed and can't be changed
    vm_size: Standard_NV12s_v3 # Standard_NV8as_v4 Only NVsv3 and NVsV4 are supported
    max_core_count: 48
    image: "MicrosoftWindowsDesktop:Windows-10:21h1-pron:latest"
    ColocateNodes: false
    spot: false

```