resource "local_file" "AnsibleInventory" { 
  content = templatefile("${local.playbooks_template_dir}/inventory.tmpl",
   {
      jumpbox-pip       = local.allow_public_ip ? azurerm_public_ip.jumpbox-pip[0].ip_address : azurerm_network_interface.jumpbox-nic.private_ip_address
      jumpbox-user      = azurerm_linux_virtual_machine.jumpbox.admin_username
      jumpbox-ssh-port  = local.jumpbox_ssh_port
      ad-ip             = azurerm_network_interface.ad-nic.private_ip_address
      ad2-ip            = local.ad_ha ? azurerm_network_interface.ad2-nic[0].private_ip_address : azurerm_network_interface.ad-nic.private_ip_address
      ad-passwd         = azurerm_windows_virtual_machine.ad.admin_password
    }
  )
  filename = "${local.playbook_root_dir}/inventory"
}

resource "local_file" "global_variables" {
  content = templatefile("${local.playbooks_template_dir}/global_variables.tmpl",
    {
      admin_username      = local.admin_username
      ssh_public_key      = tls_private_key.internal.public_key_openssh
      cc_storage          = azurerm_storage_account.azhop.name
      compute_subnetid    = local.create_compute_subnet ? "${azurerm_subnet.compute[0].resource_group_name}/${azurerm_subnet.compute[0].virtual_network_name}/${azurerm_subnet.compute[0].name}" : "${data.azurerm_subnet.compute[0].resource_group_name}/${data.azurerm_subnet.compute[0].virtual_network_name}/${data.azurerm_subnet.compute[0].name}"
      region              = local.location
      resource_group      = local.resource_group
      config_file         = local.configuration_file
      ad-ip               = azurerm_network_interface.ad-nic.private_ip_address
      ad2-ip              = local.ad_ha ? azurerm_network_interface.ad2-nic[0].private_ip_address : azurerm_network_interface.ad-nic.private_ip_address
      key_vault           = azurerm_key_vault.azhop.name
      jumpbox-ssh-port    = local.jumpbox_ssh_port      
    }
  )
  filename = "${local.playbook_root_dir}/group_vars/all.yml"
}

resource "local_file" "ci_jumpbox" {
  content = templatefile("${local.playbooks_template_dir}/jumpbox_ci.tmpl",
    {
      jumpbox-ssh-port  = local.jumpbox_ssh_port
    }
  )
  filename = "${path.root}/cloud-init/jumpbox.yml"
}

data "local_file" "ci_jumpbox" {
  filename = "${path.root}/cloud-init/jumpbox.yml"
  depends_on = [local_file.ci_jumpbox]
}