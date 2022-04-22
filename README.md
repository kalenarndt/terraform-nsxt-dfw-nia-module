# terraform-nsxt-nsxt-dfw-nia-module

### This module is specifically designed to be used with Consul-Terraform-Sync. 


---

This module will dynamically create the following objects based on the health of a service or multiple services within a task

- Custom Service (currently limited to TCP) within NSX-T. This is based on the registered port within the Consul Catalog
- Tags and Scopes 
- Policy Group based on Tag and Scope (Limited to 1 tag due to a constraint with the provider and the OR selector)
- Distributed Firewall Section per task
- 1 Rule per Service 
- 1 Deny rule per section that applies only to the services that are created.

---

## Pre-Requisites

- HashiCorp Consul 
- Consul-Terraform-Sync
- Service Metadata Definitions

---

### Service Metadata Definition

In order for Consul-Terraform-Sync to create rules with specific source and destinations, the service registration for the application service has to have a `meta` definition with a key of `downstream` and the value is the downstream service that consumes this.  An example would be `web` is downstream (consumer) of `api` so `api` will need `downstream: web`. 

If you have a service with no `downstream` dependencies this can be left blank. The source field in the Distributed Firewall definition will be defaulted to `any`

```hcl
{
  "node_name": "${name}",
  "service": {
    "id": "${name}",
    "name": "${service_name}",
    "tags": ["${service_tag}"],
    "port": ${service_port},
    "meta": {
      "downstream": "${downstream}"
    },
    "checks": [
      {
        "id": "HTTP-${service_name}",
        "name": "Checks ${service_name} on port ${service_port}",
        "http": "http://localhost:${service_port}/health",
        "interval": "5s",
        "timeout": "1s",
        "DeregisterCriticalServiceAfter": "7m"
      }
    ]
  }
}
```

---

#### Liability 
Note: This module is not officially supported by VMware or HashiCorp and should be used with caution in your environment. I am not liable for any issues this may cause. 

---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_nsxt"></a> [nsxt](#requirement\_nsxt) | >=3.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_nsxt"></a> [nsxt](#provider\_nsxt) | 3.2.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [nsxt_policy_group.security_group](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_group) | resource |
| [nsxt_policy_security_policy.policy](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_security_policy) | resource |
| [nsxt_policy_service.l4_service](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_service) | resource |
| [nsxt_policy_vm_tags.tags](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/resources/policy_vm_tags) | resource |
| [nsxt_policy_vm.check](https://registry.terraform.io/providers/vmware/nsxt/latest/docs/data-sources/policy_vm) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cts_prefix"></a> [cts\_prefix](#input\_cts\_prefix) | (Optional) Prefix that will be applied to all objects created via Consul-Terraform-Sync | `string` | `"cts-"` | no |
| <a name="input_services"></a> [services](#input\_services) | Consul services monitored by Consul Terraform Sync | <pre>map(<br>    object({<br>      id        = string<br>      name      = string<br>      kind      = string<br>      address   = string<br>      port      = number<br>      meta      = map(string)<br>      tags      = list(string)<br>      namespace = string<br>      status    = string<br><br>      node                  = string<br>      node_id               = string<br>      node_address          = string<br>      node_datacenter       = string<br>      node_tagged_addresses = map(string)<br>      node_meta             = map(string)<br><br>      cts_user_defined_meta = map(string)<br>    })<br>  )</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
