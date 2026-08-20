data "azurerm_user_assigned_identity" "jenkins" {
  name                = "jenkins-${var.env}-mi"
  resource_group_name = "managed-identities-${var.env}-rg"
}

module "finrem-vault" {
  source                       = "git@github.com:hmcts/cnp-module-key-vault?ref=DTSPO-31965/remove-jenkins-ptl-access"
  name                         = "finrem-${var.env}"
  product                      = var.product
  env                          = var.env
  tenant_id                    = var.tenant_id
  object_id                    = var.jenkins_AAD_objectId
  jenkins_object_id            = data.azurerm_user_assigned_identity.jenkins.principal_id
  resource_group_name          = azurerm_resource_group.rg.name
  product_group_name           = "dcd_divorce"
  create_managed_identity      = true
  common_tags                  = local.tags
  grant_preview_jenkins_access = var.env == "aat"
}

output "vaultName" {
  value = module.finrem-vault.key_vault_name
}

data "azurerm_key_vault" "s2s_vault" {
  name                = "s2s-${var.env}"
  resource_group_name = "rpe-service-auth-provider-${var.env}"
}

data "azurerm_key_vault_secret" "finrem_citizen_s2s" {
  name         = "microservicekey-finrem-citizen-ui"
  key_vault_id = data.azurerm_key_vault.s2s_vault.id
}

resource "azurerm_key_vault_secret" "finrem_citizen_s2s" {
  name         = "finrem-citizen-s2s-client-secret"
  value        = data.azurerm_key_vault_secret.finrem_citizen_s2s.value
  key_vault_id = module.finrem-vault.key_vault_id
}
