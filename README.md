# terraform-nsxt-dfw-nia-module

### This module is specifically designed to be used with Consul-Terraform-Sync. 


---

This module will dynamically create the following objects based on the health of a service or multiple services within a task

- Custom Service (currently limited to TCP) within NSX-T. This is based on the registered port within the Consul Catalog
- Tags and Scopes 
- Policy Group based on Tag and Scope (Limited to 1 tag due to a constraint with the provider and the OR selector)
- Distributed Firewall Section per task
- 1 Rule per Service 
- 1 Allow rule per section that applies only to the services that are created. Can be overridden

---

## Limitations

-  1 rule per service definition from Consul
-  1 tag from the service in Consul and the name of the service is always the scope 
-  Services are always TCP - We cannot determine the protocol unless we also supply custom metadata via the service registration in Consul
-  1 Tag per service (Service = Web in Consul should have all the same tag names EG. web-prod for Web1,Web2,Web3)

---

## Pre-Requisites

- HashiCorp Consul 
- HashiCorp Consul Terraform Sync
- Service Metadata Definitions

---

### Service Metadata Definition

In order for Consul-Terraform-Sync to create rules with specific source and destinations, the service registration for the application service has to have a `meta` definition with a key of `downstream` and the value is the downstream service that consumes this.  An example would be `web` is downstream (consumer) of `api`, so `api` will need `downstream: web`. 

If you have a service with no `downstream` dependencies this can be left blank. The source field in the Distributed Firewall definition will be defaulted to `any`

```hcl
{
  "node_name": "api01",
  "service": {
    "id": "api01",
    "name": "api",
    "tags": ["api-prod"],
    "port": 9091,
    "meta": {
      "downstream": "web" # consuming service
    },
    "checks": [
      {
        "id": "HTTP-api",
        "name": "Checks api on port 9091",
        "http": "http://localhost:9091/health",
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
Note: This module is not officially supported by VMware or HashiCorp.

The default section rule at the bottom defaults to `"ALLOW"` this can be overridden by forking the module and changing the defaults or by supplying `default_action = "DENY"` in a `.tfvars` file and supplying it in the Consul-Terraform-Sync `variable_files` [argument](https://www.consul.io/docs/nia/configuration#variable_files)

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
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Default action for the rule at the bottom of the section created by Consul-Terraform-Sync. | `string` | `"ALLOW"` | no |
| <a name="input_services"></a> [services](#input\_services) | Consul services monitored by Consul Terraform Sync | <pre>map(<br>    object({<br>      id        = string<br>      name      = string<br>      kind      = string<br>      address   = string<br>      port      = number<br>      meta      = map(string)<br>      tags      = list(string)<br>      namespace = string<br>      status    = string<br><br>      node                  = string<br>      node_id               = string<br>      node_address          = string<br>      node_datacenter       = string<br>      node_tagged_addresses = map(string)<br>      node_meta             = map(string)<br><br>      cts_user_defined_meta = map(string)<br>    })<br>  )</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
