# CloudEng IaCM Baseline

A Harness baseline for the CloudEng team (Anthony's group) that provides a paved road for every other team deploying infrastructure with Harness IaCM. Adapted from [`rssnyder/hrns-tf-faktory`](https://github.com/rssnyder/hrns-tf-faktory).

It addresses the four pillars CloudEng needs to own:

| Pillar | What it gives end-users | Where to look |
|---|---|---|
| **Module registry** | A documented "how to publish an internal module" path with automatic test + integration-test pipelines on every push. | `module_faktory.tf` + `./module/` |
| **Governance** | OPA controls that fire on pipeline save and after every Terraform plan, gating things like *"must use a CloudEng stage template"* and *"modules must come from an approved source"*. | `policies.tf` + `templates/policies/*.rego` |
| **Baseline executions** | Six account-level stage templates (`TF_Plan`, `TF_Apply`, `TF_Destroy`, `TF_DetectDrift`, `TF_Test`, `TF_Integration_Test`) that any pipeline in the account can drop into a stage. Pre-wired with `checkov`, approval gates, and IaCM init/plan/apply commands. | `stage_templates.tf` + `templates/stages/*.yaml` |
| **Automation** | An IDP "Create Templated Repo" workflow that scaffolds a new application repo + ready-to-attach IaCM workspace from a cookiecutter template — one click for app teams. | `idp.tf` + `repo/` cookiecutter |

## Architecture at a glance

```
Harness Account
├── (account-scope) Stage templates           ← stage_templates.tf
│     TF_Plan, TF_Apply, TF_Destroy, TF_DetectDrift, TF_Test, TF_Integration_Test
├── (account-scope) OPA policies & sets       ← policies.tf
│     template_enforcement (onsave/pipeline)
│     allowed_modules     (afterTerraformPlan/terraformPlan)
└── default/CloudEng_Platform                 ← main.tf
      ├── Pipelines: TF_Module_Testing, TF_Module_Integration_Testing  ← module_faktory.tf
      ├── Pipeline:  Create_Templated_Repo                             ← idp.tf
      ├── IDP Workflow: Create Templated Repo                          ← idp.tf
      └── (per registered module)
            harness_platform_infra_module
            harness_platform_infra_module_testing
```

End-user teams' projects live alongside `CloudEng_Platform`. Their pipelines just `templateRef: account.TF_Plan` (etc.) and the governance + execution semantics come along for free. See `projects.tf` and `./project/` for the end-user bootstrap pattern.

## Layout

```
.
├── README.md                      ← you are here
├── terraform.tf                   ← provider versions + backend
├── providers.tf                   ← harness provider config
├── variables.tf                   ← all inputs
├── locals.tf                      ← tags + rendered IaCM/IDP infra snippets
├── main.tf                        ← CloudEng Platform project
├── stage_templates.tf             ← Pillar 3: 6 account-scope IaCM stage templates
├── policies.tf                    ← Pillar 2: OPA policies + policy sets
├── module_faktory.tf              ← Pillar 1: module test pipelines + (commented) module reg
├── idp.tf                         ← Pillar 4: IDP workflow + create-repo pipeline
├── pipelines.tf                   ← end-user demo: Application_Deploy (Plan + Apply)
├── projects.tf                    ← end-user project bootstrap example (commented)
├── outputs.tf                     ← refs end users / downstream stacks need
├── terraform.tfvars.example       ← copy → terraform.tfvars
├── examples/
│   └── consumer-app/              ← end-user TF showing how to use the 'example' module
├── module/                        ← submodule: register a module in the registry
├── project/                       ← submodule: bootstrap an end-user project
├── repo/                          ← cookiecutter template for new app repos
└── templates/
    ├── snippets/                  ← shared infra/k8s/runtime snippets
    ├── stages/                    ← stage-template YAMLs
    ├── pipelines/                 ← pipeline YAMLs (module testing, repo create)
    ├── policies/                  ← .rego sources for the OPA policies
    └── workflows/                 ← IDP workflow YAML
```

## End-to-end live demo (current state of the account)

To prove the four pillars round-trip against real entities, the following are already live in the `Nqvj4rBDR2KoKrjGhauyVg` account — created either out-of-band (the module registry entry, the GitHub connector) or via the MCP during setup (everything in `cloudeng_platform`).

| # | Entity | Identifier / location | Pillar | Notes |
|---|---|---|---|---|
| 1 | GitHub connector | `account.NandeeshAccountLevel` | — | Account-scope; points at a fork of `rssnyder/hrns-tf-faktory`. Used both as the module's source repo and as `template_clone_connector_ref` for the IDP workflow. |
| 2 | IaCM module | `example` (system `tf`, repo `hrns-tf-faktory`, branch `main`) | 1: Module registry | Created via the Harness UI; consumer reference is `app.harness.io/Nqvj4rBDR2KoKrjGhauyVg/example/tf`. |
| 3 | Project | `default/cloudeng_platform` (modules: IACM, IDP, CODE, CI) | — | Houses everything CloudEng owns. |
| 4 | Stage template | `TF_Plan` v1 (project-scope demo) | 3: Baseline executions | OpenTofu init → Checkov → plan. |
| 5 | Stage template | `TF_Apply` v1 (project-scope demo) | 3: Baseline executions | OpenTofu init → plan → IACMApproval → apply. |
| 6 | OPA policy | `template_enforcement` | 2: Governance | Denies untemplated / non-account IaCM stages. |
| 7 | OPA policy | `allowed_modules` | 2: Governance | Module-source allow-list + pinned versions + resource-types-in-modules. |
| 8 | Policy set | `iacm_pipeline` (onsave / pipeline) | 2: Governance | Binds `template_enforcement` (warning). Enabled. |
| 9 | Policy set | `iacm_plan` (afterTerraformPlan / terraformPlan) | 2: Governance | Binds `allowed_modules` (warning). Enabled. |
| 10 | Pipeline | `cloudeng_platform/Application_Deploy` | 3 + 2 (round-trip) | Chains stages `TF_Plan` → `TF_Apply`, both referencing the project-scope templates above with `workspace` as runtime input. |

### The governance round-trip you can already see in the UI

When `Application_Deploy` was saved, the `template_enforcement` policy fired at **warning** severity:

> _IaCM stage 'TF Apply' does not use an account level template_
> _IaCM stage 'TF Plan' does not use an account level template_

That's working as designed — the policy is doing its job, the severity is `warning` so the pipeline still saves. Once this baseline's `terraform apply` lands and creates the **account-scope** versions of `TF_Plan` / `TF_Apply`, the `pipelines.tf` Terraform here will swap the `templateRef` from `TF_Plan` to `account.TF_Plan` and the warning disappears. Flip the policy severity from `warning` to `error` in `policies.tf` once teams are compliant.

### End-to-end flow once `terraform apply` has run

```
1.  CloudEng publishes module 'example' to the Harness module registry
    (already done via UI; described under "Pillar 1" below)
            │
            ▼
2.  Application team clicks IDP → Workflows → "Create Templated Repo"
    (idp.tf creates this) — IDP triggers Create_Templated_Repo pipeline
            │
            ▼
3.  Create_Templated_Repo:
        CreateRepo → GitClone → CookieCutter → DirectPush
    (results in a new GitHub repo with infra/main.tf scaffolded)
            │
            ▼
4.  CloudEng (or app team) creates an IaCM workspace pointing at the new
    repo's infra/ directory; workspace name = e.g. acme_dev
    (harness_platform_workspace via the Terraform provider; not creatable
     via the MCP — see ../harness-iacm-workspaces/ for the pattern)
            │
            ▼
5.  App team runs Application_Deploy in their project (or in cloudeng_platform
    for the demo), picks `workspace: acme_dev` from the runtime input
            │
            ▼
6.  TF_Plan stage runs:
        init  → checkov (high-sev gate) → plan
    `allowed_modules` policy walks the plan: every module call must start
    with ./, ../, app.harness.io/, or terraform-aws-modules/. The team's
    `module "example" { source = "app.harness.io/.../example/tf" }` passes.
            │
            ▼
7.  TF_Apply stage runs:
        init → plan → IACMApproval (manual gate) → apply
    Apply succeeds; module 'example' provisions whatever it provisions.
            │
            ▼
8.  Drift detection (TF_DetectDrift template) can be scheduled on a trigger.
    Changes to the module repo automatically run TF_Module_Testing and
    TF_Module_Integration_Testing per `module_faktory.tf`.
```

### Try the demo right now (no `terraform apply` needed)

1. Open [`cloudeng_platform/Application_Deploy`](https://app.harness.io/ng/account/Nqvj4rBDR2KoKrjGhauyVg/all/orgs/default/projects/cloudeng_platform/pipelines/Application_Deploy/pipeline-studio) → Pipeline Studio.
2. Click "Policy Evaluations" — you'll see the warning from `template_enforcement` fire on every save.
3. Hit "Run" — it'll prompt for a `workspace` identifier. (You don't have a workspace yet, so the run will fail at the IaCM step. That failure is also expected output until step 4 below.)
4. To make the run *succeed*, create an IaCM workspace pointing at the `hrns-tf-faktory` fork (or any repo with valid Terraform) and re-run with that workspace identifier. The fastest way to get a workspace is the existing `../harness-iacm-workspaces/main.tf` next to this baseline — `terraform apply` it once with your PAT.

## Prereqs

Before `terraform apply`:

1. **Harness PAT or SAT** with these resource permissions:
   - **Pipelines**: Create, Edit, View, Execute
   - **Templates** (account scope): Create, Edit, View
   - **Connectors**: View (Create if you also manage Git connectors here)
   - **IaCM**: Full
   - **Governance / Policy**: Create, Edit, View
   - **IDP**: Catalog Entity create
   - **Project**: Create, View

   Export it: `export TF_VAR_harness_platform_api_key="pat.<acct>.<id>.<secret>"`.

2. **Account-scope Git connector(s)** referenced from `terraform.tfvars`:
   - `git_connector_ref` — used by the IDP "Create Templated Repo" workflow to create new app repos
   - `template_clone_connector_ref` — used to clone this baseline (so cookiecutter can read `repo/`)

   Both can be the same connector when this baseline lives in the same Git org as the apps it scaffolds.

3. **A copy of this repo pushed to Git** at the location pointed to by `template_clone_repo_name` (so the IDP workflow can clone it at runtime to read the `repo/` cookiecutter).

## Quickstart

```bash
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars                       # fill in account_id, git connectors, git_org
export TF_VAR_harness_platform_api_key="pat.<acct>.<id>.<secret>"

terraform init
terraform plan
terraform apply
```

After apply:

- Six stage templates are live at account scope and can be referenced as `account.TF_Plan` etc. from any pipeline in the account.
- Two OPA policy sets are enabled at **warning** severity. Flip to `error` in `policies.tf` once teams are compliant.
- `default/CloudEng_Platform` exists with the module test pipelines + IDP repo-create pipeline + IDP workflow.

## Pillar 1 — Module registry: develop, test, publish

```
                       PR/push  ┌──────────────────────┐
                  ┌────────────►│ TF_Module_Testing    │ → on-PR status check
   module repo ──┤              └──────────────────────┘
   (cloudeng/    │              ┌──────────────────────┐
    terraform-X) └─────────────►│ TF_Module_Integration│ → on-PR status check
                                │ _Testing             │
                                └──────────────────────┘
                                          │
                                          ▼
                                 ┌────────────────────┐
                                 │ Harness module     │
                                 │ registry (visible  │
                                 │ to all workspaces) │
                                 └────────────────────┘
```

### To publish a new module

1. Create a Git repo `cloudeng/terraform-<provider>-<thing>` containing standard Terraform: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`, and an `examples/` directory with at least one runnable example (this is what `IACMModuleTestPlugin` exercises).
2. Add a module block to `module_faktory.tf` (uncomment the example block) pointing at the new repo, then `terraform apply`.

```hcl
module "my_module" {
  source = "./module"

  name                 = "vpc"
  description          = "Opinionated CloudEng AWS VPC module"
  system               = "networking"
  repository_connector = "account.github_cloudeng"
  repository           = "cloudeng/terraform-aws-vpc"
  repository_branch    = "main"
  repository_path      = ""
  provider_connector   = "account.aws_cloudeng_sandbox"
  provisioner_type     = "opentofu"
  provisioner_version  = "1.7.5"
  testing_pipelines = [
    harness_platform_pipeline.testing.identifier,
    harness_platform_pipeline.integration_testing.identifier,
  ]

  org_id     = data.harness_platform_organization.platform_org.id
  project_id = harness_platform_project.platform_project.identifier
}
```

3. End-users now consume the module via:

```hcl
module "vpc" {
  source = "app.harness.io/<account-id>/vpc/aws"
  version = "1.0.0"
  # ...
}
```

…and the `allowed_modules` OPA policy permits this source automatically.

### Why two test pipelines?

| Pipeline | When it runs | What it does | Cost |
|---|---|---|---|
| `TF_Module_Testing` | every push | `terraform init && validate` on each `examples/*` directory using `IACMModuleTestPlugin command: test`. Fast, no cloud resources. | none |
| `TF_Module_Integration_Testing` | label or manual trigger | full `init → plan → apply → destroy` against the `provider_connector` (real cloud). Catches drift between examples and actual provider behavior. | real cloud spend |

The module-factory pipelines are inline (not stage-template based) because IaCM module test plugins don't yet support stage-template references — when that lands, swap them over and the `account.TF_Test` / `account.TF_Integration_Test` templates take over.

## Pillar 2 — Governance: OPA controls on what end-users deploy

Two policies live at account scope:

### `template_enforcement.rego` — bound to `iacm_pipeline` (onsave / pipeline)

Fires when an end-user **saves** an IaCM pipeline. Denies if:

1. An IaCM stage has no template at all (`stage.template` missing).
2. An IaCM stage uses a template that is not account-scoped (`templateRef` doesn't start with `account.`).

Net effect: end-users can't bypass CloudEng's `TF_Plan`/`TF_Apply`/etc. and write raw IaCM stages.

### `allowed_modules.rego` — bound to `iacm_plan` (afterTerraformPlan / terraformPlan)

Fires after every IaCM `plan` step. Three rules:

1. **Approved sources only** — module source must start with `../`, `./`, `app.harness.io/`, or `terraform-aws-modules/`. Tune this list in the rego to match your real allow-list.
2. **Pinned versions on sensitive modules** — example shows `terraform-aws-modules/kms/aws` pinned to `["2.2.0", "2.3.0"]`. Add more pinned modules as the team grows.
3. **Resources only inside modules** — only an allow-listed set of resource types (e.g. `aws_cloudwatch_log_group`) may be declared at the root; everything else must be wrapped in a module so it benefits from review + tests.

### Rollout strategy

The policies in `policies.tf` ship with `severity = "warning"` so they highlight but don't block. After one sprint of observation, flip to `"error"` for `template_enforcement` first (low risk), then `allowed_modules` once teams have time to clean up.

### Adding a policy

1. Drop the `.rego` under `templates/policies/`.
2. Add a `harness_platform_policy` block in `policies.tf` pointing at it.
3. Reference it from one of the existing `policyset`s, or create a new one for a different event/entity.
4. `terraform apply`.

## Pillar 3 — Baseline executions: the six stage templates

Each is an *account-scope* `Stage` template that renders an `IACM` stage. They share two snippets:

- `templates/snippets/iacm_infrastructure.yaml` — toggles between **Harness Cloud** runtime (default) and a **self-hosted Kubernetes** infrastructure block based on `var.kubernetes_connector`.
- `templates/snippets/tf_step.yaml` — toggles between Terraform plugin (`IACMTerraformPlugin`) and OpenTofu plugin (`IACMOpenTofuPlugin`) per `var.provisioner_type`, with an optional override image.

| Template | Steps | Used when |
|---|---|---|
| `TF_Plan` | init → checkov → plan | every PR; drift visualization |
| `TF_Apply` | init → plan → **IACMApproval** → apply | main-branch merges to prod-like envs |
| `TF_Destroy` | init → plan-destroy → **IACMApproval** → destroy | retirement workflows |
| `TF_DetectDrift` | init → detect-drift | scheduled triggers (nightly/hourly) |
| `TF_Test` | IACMModuleTestPlugin `test` | module factory unit tests |
| `TF_Integration_Test` | IACMModuleTestPlugin `integration-test` | module factory cloud tests |

### Consuming a template from an end-user pipeline

```yaml
stages:
  - stage:
      name: TF Plan
      identifier: TF_Plan
      tags: {}
      template:
        templateRef: account.TF_Plan
        versionLabel: v1
        templateInputs:
          type: IACM
          spec:
            workspace: my_workspace_identifier
```

The `./project/` submodule generates exactly that YAML for any project you bootstrap through it — see `projects.tf` for the example.

### Switching a team to self-hosted execution

Set `kubernetes_connector = "account.build_farm"` (and the related k8s vars) in `terraform.tfvars`, `terraform apply`, and every account template re-renders. No end-user pipeline changes required.

## Pillar 4 — Automation: bootstrap a new application with IDP

The IDP "Create Templated Repo" workflow appears in **Internal Developer Portal → Workflows**. An app team fills in:

- repo name
- description
- target Harness project

…and on submit, IDP triggers `Create_Templated_Repo` (in `CloudEng_Platform`), which:

1. **CreateRepo** — creates a new private repo in `var.git_org` via `var.git_connector_ref`
2. **GitClone** — clones this baseline into `/template`
3. **CookieCutter** — renders the `repo/{{cookiecutter.project_slug}}` template
4. **DirectPush** — pushes the rendered content to the new repo on `var.repo_branch`

The new repo lands with:

```
my_new_app/
├── README.md
├── .gitignore
├── app/index.html       ← placeholder; teams replace with their service
└── infra/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tf
└── infra-vars/
    ├── dev.tfvars
    ├── qa.tfvars
    └── prod.tfvars
```

…ready for the team to point an IaCM workspace at `infra/` and start landing PRs.

### Extending the cookiecutter

Edit `repo/cookiecutter.json` to add prompts, and add the corresponding `{{ cookiecutter.<var> }}` placeholders inside `repo/{{cookiecutter.project_slug}}/`. Commit + push and the next IDP run picks them up — no `terraform apply` needed for the cookiecutter itself (Harness clones it fresh each run).

To also auto-create the IaCM workspace at scaffold time, add a `harness_platform_workspace` step after the `DirectPush` step in `templates/stages/create_templated_repo.yaml`. The `harness-iacm-workspaces/` repo next to this one has a working `harness_platform_workspace` example you can lift.

## Day-2 operations

### Bumping a stage template

1. Edit the YAML under `templates/stages/`.
2. Bump `version` in `stage_templates.tf` (e.g. `v1` → `v2`).
3. Decide whether to flip `is_stable = true` for the new version (auto-roll consumers) or keep it false (opt-in).
4. `terraform apply`. Existing pipelines pinned to v1 keep working; new pipelines (and pipelines that consume the "stable" version) pick up v2.

### Onboarding a new team / project

Uncomment a `module "project_<team>"` block in `projects.tf`, set their `project_id`, `terraform apply`. They now have `TF_Plan`/`TF_Apply`/`TF_Destroy`/`TF_Drift` pipelines pre-wired in their project.

### Auditing what's been deployed

Every CloudEng-managed resource carries `created_by:Terraform` and `factory:cloudeng-iacm-baseline` tags (see `locals.tf`). Use the Harness Audit Trail or `harness_list resource_type=audit_event` to find non-conforming resources.

### Reverting a bad rollout

`terraform plan` first — every resource is in state, so destructive changes are visible up front. Stage templates and policies are versioned; pin consumers to the previous version label before changing/removing.

## Known limitations & TODO

- **Module test plugins can't yet use stage templates.** `module_faktory.tf` uses inline pipelines because of this — swap to template-based once `IACMModuleTestPlugin` supports `templateRef`.
- **`allowed_modules` allow-list is illustrative.** Edit `templates/policies/allowed_modules.rego` to match the team's real curated source list (private module registry namespaces, internal Git hosts, etc.).
- **OPA policy sets ship at `severity = "warning"`.** Flip to `"error"` once teams are clean.
- **No backend configured.** Uncomment the `backend` block in `terraform.tf` and point it at the team's remote state store before sharing this with the rest of CloudEng.
- **One Git provider supported in the IDP workflow.** Extend `templates/stages/create_templated_repo.yaml` if CloudEng needs multi-provider (GitHub + GitLab) support.

## Reference

- Upstream factory: https://github.com/rssnyder/hrns-tf-faktory
- Harness Terraform provider: https://registry.terraform.io/providers/harness/harness/latest/docs
- IaCM docs: https://developer.harness.io/docs/infra-as-code-management
- OPA / Policy Engine docs: https://developer.harness.io/docs/platform/governance/policy-as-code
- IDP docs: https://developer.harness.io/docs/internal-developer-portal
