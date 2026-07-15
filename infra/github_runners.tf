# User assigned identity is required to avoid circular dependencies on access between key vault, registry and container job.
resource "azurerm_user_assigned_identity" "github_runner" {
  name                = "id-github-runner-${random_string.this.id}"
  resource_group_name = azurerm_resource_group.github_runner.name
  location            = azurerm_resource_group.github_runner.location
}

resource "azurerm_container_app_environment" "runner_env" {
  name                = "cae-github-runners-${random_string.this.id}"
  resource_group_name = azurerm_resource_group.github_runner.name
  location            = azurerm_resource_group.github_runner.location

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  logs_destination           = "log-analytics"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.github_runner.id]
  }

  workload_profile {
    maximum_count = 0
    minimum_count = 0

    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_role_assignment" "runner_env_registry" {
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.github_runner.principal_id
  principal_type       = "ServicePrincipal"
  scope                = azurerm_container_registry.this.id
}

resource "azurerm_role_assignment" "runner_job_kv" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.github_runner.principal_id
  principal_type       = "ServicePrincipal"
  scope                = azurerm_key_vault.github_runner.id
}

# We need to use azapi instead of azurerm provider because identitySettings/lifecycle is not supported yet and we need to controll that here.
# See: https://github.com/hashicorp/terraform-provider-azurerm/issues/28234
resource "azapi_resource" "runner_job" {
  type      = "Microsoft.App/jobs@2025-10-02-preview"
  name      = "caj-github-runners-${random_string.this.id}"
  parent_id = azurerm_resource_group.github_runner.id
  location  = azurerm_resource_group.github_runner.location

  body = {
    properties = {
      environmentId = azurerm_container_app_environment.runner_env.id
      configuration = {
        eventTriggerConfig = {
          parallelism            = 1
          replicaCompletionCount = 1
          scale = {
            maxExecutions   = 100
            minExecutions   = 0
            pollingInterval = 30
            rules = [{
              auth = [{
                secretRef        = "gh-token"
                triggerParameter = "personalAccessToken"
              }]
              metadata = {
                labels          = var.runner_labels
                owner           = var.github_org
                repos           = var.github_repo
                runnerScope     = "repo"
              }
              name = "github-runner-scaling"
              type = "github-runner"
            }]
          }
        }
        identitySettings = [
          # Important to set identities to None for availability in the container. This ensures the Azure identity isn't available for use from GitHub workflows.
          {
            identity  = azurerm_user_assigned_identity.github_runner.id,
            lifecycle = "None"
        }]
        registries = [{
          identity = azurerm_user_assigned_identity.github_runner.id
          server   = azurerm_container_registry.this.login_server
        }]
        replicaTimeout = 1800
        secrets = [{
          name        = "gh-token"
          keyVaultUrl = azurerm_key_vault_secret.github_pat.versionless_id
          identity    = azurerm_user_assigned_identity.github_runner.id
        }]
        triggerType = "Event"
      }
      template = {
        containers = [{
          env = [
            {
              name  = "GITHUB_ORG"
              value = var.github_org
            },
            {
              name  = "GITHUB_REPO"
              value = var.github_repo
              },
              {
              name  = "RUNNER_NAME"
              value = ""
              },
              {
              name  = "RUNNER_LABELS"
              value = var.runner_labels
              },
              {
              name      = "GITHUB_PAT"
              secretRef = "gh-token"
          }]
          image     = "${azurerm_container_registry.this.login_server}/github-runner:latest"
          imageType = "ContainerImage"
          name      = "caj-github-runners"
          probes    = []
          resources = {
            cpu    = 0.75
            memory = "1.5Gi"
          }
        }]
      }
      workloadProfileName = "Consumption"
    }
  }
  identity {
    identity_ids = [azurerm_user_assigned_identity.github_runner.id]
    type         = "UserAssigned"
  }

  depends_on = [
    azurerm_role_assignment.runner_env_registry,
    azurerm_role_assignment.runner_job_kv
  ]
}
