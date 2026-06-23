# harness tf faktory

this repo contains terraform code for the harness tf faktory project, which outlines everything needed to provide a baseline for running terraform, providing modules, and governance when using the harness platform.

<img width="3821" height="2578" alt="image" src="https://github.com/user-attachments/assets/246dc13e-196d-41db-b46c-5c7fd3d9c762" />

## stage_templates

this file contains account level stage templates for the common infrasture usage patterns:

- planning changes
- applying changes
- destroying resources
- checking for drift
- testing modules
- integration testing modules

the templates can either use harness hosted compute or run on self-hosted kubernetes. by default they use harness hosted compute but you can set a kubernetes connector to enable self-hosted execution:

```
kubernetes_connector = "account.build_farm"
```

you can see the variables defined in `variables.tf` for more kubernetes configuration options.

if you are using self-hosted infrastructure, and you cannot resolve the default harness tf image (`harness/harness_terraform`) you can set a custom image (and connector) via input variables:

```
plugin_image = "acmecorp/harness_terraform"
plugin_connector = "account.docker_registry"
```

<img width="3809" height="1398" alt="image" src="https://github.com/user-attachments/assets/0ff599ab-9d50-406e-be77-263e57820279" />

## policies

this file contains account level policies for the common infrastructure usage patterns:

- requiring all iacm stages use the account level templates
- requiring modules to come from an approved source
- requiring specific versions of a specific module
- requiring specific resource types to only be created within modules

these policies are enforced at the account level and apply to all pipelines in the account.

they should server as starting points for your organization's governance requirements.

## module_faktory

this file creates a project to be used for testing of infrastructure modules. it comes with pipelines that leverage the stage templates to test modules with both terratest and integration tests by spinning up all `examples` in the modules directory.

there is then a tf-module created to register a new module in harness along with the testing settings to run all changes through pipelines.

<img width="1894" height="1203" alt="image" src="https://github.com/user-attachments/assets/7b1064af-52d2-4716-9d84-ea6a7a1ed4b1" />

## repo template

the `repo` directory contains a cookiecutter template for creating new repos with the standard structure.
