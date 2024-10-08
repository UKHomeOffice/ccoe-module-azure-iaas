# CCoE Module - Azure IaaS Build
This Terraform module provides a baseline Azure infrastructure as a service (IaaS) build.

It supports the creation of:
- Virtual Machines (VMs)
- Storage Accounts
- Networking
- Disks
- Network Security Groups (NSGs)
- Recovery Services Vaults (RSVs)

By using this module you ensure that:
- All resources are built to a standard pattern
- All resources follow the recommended naming guidance
- All resources have appropriate tags applied
- Built-in security baselines are applied

## Example Usage

The module can be called from your Terraform as shown in this example below:

```

module "example" {
  source = "github.com/UKHomeOffice/ccoe-module-azure-iaas"

    # ---------------------------------------------------------
    # Environment & Region
    # ---------------------------------------------------------

    vrf                        = "HO1"
    env_name                   = "Prd"
    deployment_region_friendly = "UKSouth"
    deployment_region          = "uksouth"
    descriptor                 = "Example"
  
    # ---------------------------------------------------------
    # Tags
    # ---------------------------------------------------------

    tags = {
        CostCentre = "1234567.12"
        Env        = "Prd"
        Owner      = ""
        Repository = "https://github.com/UKHomeOffice/ccoe-module-azure-iaas"
        Script     = "Terraform"
        Service    = "Example Service"
        Project    = "Example Project"
        ProjectID  = "Example ID"
    }

    # ---------------------------------------------------------
    # Networking
    # ---------------------------------------------------------

    address_space = "10.10.10.0/24"
    dns_servers   = ["10.10.1.1","10.10.1.2","10.10.1.3","10.10.1.4"]

    subnets = {
      "Frontend" = {
        cidr = "10.10.10.0/27"
      }
      "Backend" = {
        cidr = "10.10.10.64/27"
      }
    }

    # ---------------------------------------------------------
    # Virtual Machines
    # ---------------------------------------------------------

    admin_username = "adminuser"

    virtual_machines = {
      "1" = { # Zone
        "APP01" = { # Hostname
            is_windows = false
            size       = "Standard_B4ms"
            subnet     = "Frontend"
            ip         = "10.10.10.11"
            nsg        = "Frontend"
            disk_set   = "app"
            image_ref  = {
              publisher = "Canonical"
              offer     = "0001-com-ubuntu-server-jammy"
              sku       = "22_04-lts"
              version   = "latest"
            }
        }
        "APP02" = { # Hostname
            is_windows = false
            size       = "Standard_B4ms"
            subnet     = "Frontend"
            ip         = "10.10.10.12"
            nsg        = "Frontend"
            disk_set   = "app"
            image_ref  = {
              publisher = "Canonical"
              offer     = "0001-com-ubuntu-server-jammy"
              sku       = "22_04-lts"
              version   = "latest"
            }
        }
        "SQL01" = { # Hostname
            size          = "Standard_A4_v2"
            subnet        = "Backend"
            ip            = "10.10.10.71"
            disk_set      = "db"
            backup_policy = "SQL"
        }
        "SQL02" = { # Hostname
            size          = "Standard_A4_v2"
            subnet        = "Backend"
            ip            = "10.10.10.72"
            disk_set      = "db"
            backup_policy = "SQL"
        }
      }
    }

    # ---------------------------------------------------------
    # Disk Sets
    # ---------------------------------------------------------

    # Please give the disks keys nice names as they will be
    # used in the resource name. (e.g no underscores!)

    disk_sets = {
      db = {
        Ancillary = {
          lun  = 10,
          size = 20
        }
        Application = {
          lun  = 15,
          size = 80
        }
        Backup = {
          lun  = 20,
          size = 100
        }
        Data = {
          lun  = 25,
          size = 100
        }
        Log = {
          lun  = 30,
          size = 100
        }
        PageFile = {
          lun  = 35,
          size = 20
        }
        TempData = {
          lun  = 40,
          size = 150
        }
        TempLog = {
          lun  = 45,
          size = 150
        }
      }
      app = {
        PageFile = {
          lun  = 35,
          size = 12
        }
      }
    }

    # ---------------------------------------------------------
    # Storage Accounts
    # ---------------------------------------------------------

    storage_accounts = {
      "teststorageaccount" = {
        containers = {
          "testcontainer" = {
            access_type = "public"
          }
        }
        shares = {
          "test" = {
            quota       = 50
            access_type = "public"
          }
        }
        private_endpoints = {
          blob = {
            subnet = "Backend"
            ip     = "10.10.10.69"
          }
        }
      }
    }

    # ---------------------------------------------------------
    # Network Security Groups
    # ---------------------------------------------------------

    baseline_cidrs = {
      management         = ["192.168.1.0/24"]
      domain_controllers = ["10.10.10.0/24"]
      proxy              = ["10.10.11.0/24"]
      snmp               = ["10.10.12.0/24"]
      ntp                = ["10.10.13.0/24"]
      sccm               = ["10.10.14.0/24"]
      scom               = ["10.10.15.0/24"]
      package_repo       = ["10.10.16.0/24"]
      kms                = ["10.10.17.0/24"]
    }

    # When defining NSG priorities be aware that baseline rules
    # start from priority 1000. Therefore user defined rules here
    # must be either 100 - 1000 (recommended for explicit DENY rules only)
    # or greater than the sum of all of the baseline rules + 1000.
    
    # The recommendation is to start at priority 2000 as this gives
    # 1000 rules free for baseline and 2096 free for user defined.

    # Explicit DENY overriding rules should then use 100 - 1000.

    network_security_groups = {
      Frontend = {
        baselines = ["windows", "linux"]
        rules = {
          "Testing" = {
            priority                   = 2000
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"        
          }
        }
      }
    }

    # ---------------------------------------------------------
    # Backup Policies
    # ---------------------------------------------------------

    backup_policies = {
      "SQL" = {
        frequency = "Hourly"
        time      = "00:00"
        hour_interval = 4
        hour_duration = 4
        retention_daily = {
          count = 30
        }
      }
    }
}

```