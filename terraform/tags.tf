locals {
    rg_tags = {
        location            = var.azureRegion
        Environment = var.environment
        AppName = var.applicationName
    }

    resource_tags = {
        CretedDate = timestamp()
    }
}