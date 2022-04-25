locals {

  # Local for section name to populate all services
  cts_service_names = join(" ", distinct([for _, s in var.services : s.name]))

  # Service as key with nested maps
  consul_service_view = {
    # Set the value of id as the key for the map
    for k, v in var.services : v.name => {
      # Set the value of name, the ip address of the node - iterating via key, setting the port, and setting the tags
      ip = (var.services[k].address == "" ? var.services[k].node_address : var.services[k].address), port = v.port, meta = v.meta, id = v.id, tags = { for k, v in distinct(var.services[k].tags) : k => v }
    }...
  }

  # ID as key used with VM lookup
  consul_service_view_map = {
    # Set the value of id as the key for the map
    for k, v in var.services : v.id => {
      # Set the value of name, the ip address of the node - iterating via key, setting the port, and meta data values.                            # Creating a sub map for the tags with a number for the key and associating a key as the value
      name = v.name, ip = (var.services[k].address == "" ? var.services[k].node_address : var.services[k].address), port = v.port, meta = v.meta, tags = { for k, v in var.services[k].tags : k => v }
    }
  }
}

# Lookup the workload based on the id of the node from the Consul catalog. If it doesn't match the VM name this will fail.
data "nsxt_policy_vm" "check" {
  for_each     = local.consul_service_view_map
  display_name = each.key
}

# Assign all tags associated in the Consul catalog to the VM in NSX-T
resource "nsxt_policy_vm_tags" "tags" {
  for_each    = local.consul_service_view_map
  instance_id = try(lookup(data.nsxt_policy_vm.check, each.key, "") != "" ? data.nsxt_policy_vm.check[each.key].id : "")

  dynamic "tag" {
    for_each = local.consul_service_view_map[each.key].tags
    content {
      tag   = tag.value       # Tag value
      scope = each.value.name # Name of the application in CTS
    }
  }
}

##
##  ALL SERVICE INSTANCES THAT ARE A PART OF A SERVICE MUST HAVE THE SAME TAGS OR ELSE MEMBERSHIP WILL BE AN ISSUE
##  CONJUCTION BLOCK IS OUTSIDE OF THE CRITERIA BLOCK AND CANNOT BE CREATED IN A DYNAMIC MATTER
##
resource "nsxt_policy_group" "security_group" {
  for_each     = local.consul_service_view
  display_name = "${var.cts_prefix}${each.key}"

  criteria {
    dynamic "condition" {
      for_each = each.value[0].tags
      content {
        key         = "Tag"
        member_type = "VirtualMachine"
        operator    = "CONTAINS"
        value       = "${each.key}|${condition.value}"
      }
    }
  }
}

locals {
  # Gives us a list of all policy paths associated with the security groups in the run. This is used for the default deny at the bottom of the CTS section.
  policy_path_list = [for _, s in nsxt_policy_group.security_group : s.path]
}

# Assumes each node registered to the service is using the same port (they should be)
# EG 2 entries for API will return the following:[9091,9091,] and then we dedupe with distinct then pick the first entry and convert it to a string
resource "nsxt_policy_service" "l4_service" {
  for_each     = local.consul_service_view
  description  = "Service for ${var.cts_prefix}${each.key} created by Consul-Terraform-Sync"
  display_name = "${var.cts_prefix}${each.key}_service"

  l4_port_set_entry {
    display_name      = "${var.cts_prefix}${each.key} port"
    description       = "${var.cts_prefix}${each.key} port entry created by Consul-Terraform-Sync"
    protocol          = "TCP" # could be custom metadata object entries in the registered service
    destination_ports = ["${tostring(one(distinct(each.value.*.port)))}"]
  }

  tag {
    scope = each.key
  }
}

# Creates a Security Policy Section for the Task and adds all monitored services to the section.  Display and description update when service entries change.
resource "nsxt_policy_security_policy" "policy" {
  # Checking that the policy path list is greater than 1. If this is true then we create a map if false then we provide an empty map
  # Thanks Tom Straub for helping with this
  for_each     = length(local.policy_path_list) >= 1 ? { "cts_policy" : "" } : {}
  display_name = "Consul-Terraform-Sync Section for ${local.cts_service_names}"
  description  = "Section for ${local.cts_service_names} Consul-Terraform-Sync Rules"
  category     = "Application"
  stateful     = true
  locked       = false

  dynamic "rule" {
    for_each = local.consul_service_view
    content {
      display_name       = "${var.cts_prefix}${rule.key}_rule"
      action             = "ALLOW"
      source_groups      = lookup(nsxt_policy_group.security_group, rule.value[0].meta.downstream, []) != [] ? [nsxt_policy_group.security_group[rule.value[0].meta.downstream].path] : []
      services           = [nsxt_policy_service.l4_service[rule.key].path]
      destination_groups = [nsxt_policy_group.security_group[rule.key].path]

      # Going to need to find something where we can default to an object if a downstream value isn't present in metadata
      scope = lookup(nsxt_policy_group.security_group, rule.value[0].meta.downstream, []) != [] ? [nsxt_policy_group.security_group[rule.value[0].meta.downstream].path, nsxt_policy_group.security_group[rule.key].path] : [nsxt_policy_group.security_group[rule.key].path]
    }
  }

  dynamic "rule" {
    # Checking that the length is greater than 1 to create 1 rule but add all policy paths to the scope for dfw enforcement
    # Thanks Tom Straub for helping with this
    for_each = length(local.policy_path_list) >= 1 ? ["true"] : []
    content {
      display_name = "Consul-Terraform-Sync Drop"
      action       = var.default_action
      logged       = true
      scope        = local.policy_path_list
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}