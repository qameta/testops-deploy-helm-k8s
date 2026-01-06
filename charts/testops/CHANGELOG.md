# Change log

All notable changes to this Helm chart will be documented in this file.

Entries are ordered by priority:

1. `[CHANGE]` Breaking changes
2. `[FEATURE]` New functionalities or configurations
3. `[ENHANCEMENT]` Improvements to existing features
4. `[BUGFIX]` Fixes for defects
5. `[DOCS]` Update of the documentation in `values.yaml`

## 5.25.8

- [BUGFIX] Fixed a defect with quoting of AWS SQS variables that prevented the chart from being deployed.
- [DOCS] Adds comments on the usage of AWS SQS, IAM roles and standard names of the queues an end user needs to create on AWS SQS side prior to using SQS with Allure TestOps.

## 5.25.7

- [BUGFIX] Fixed a defect in `testops-svc` template that prevented the chart from being deployed.

## 5.25.6

- [ENHANCEMENT] Added possibility to disable OpenID token TTL control via `ignoreOpenIDSessionDurationControl`
  - `ignoreOpenIDSessionDurationControl`
    - if set to `false`, then the idle user session TTL will be controlled by OpenID IdP token TTL control.
    - if set to `true`, then idle user session TTL will be controlled by `inactiveUserSessionDuration` parameter.

## 5.25.5

- [BUGFIX] Added a dedicated sentinel password in Redis configuration.

## 5.25.4

- [BUGFIX] Fixed rendering of `sentinel.nodes` property in Redis configuration.

## 5.25.3

- [ENHANCEMENT] Adds support of `S3_SHARDED` type for S3.

## 5.25.2

- [BUGFIX] Added SQS secrets to secret.yaml and vault.yaml

## 5.25.0

- [FEATURE] Added support of AWS SQS messaging service.

## 5.21.1

- [ENHANCEMENT] Removed hyphen (`-`) from environment variable names in datasource migration configuration for improved naming consistency. For example: `SPRING_DATASOURCE-MIGRATION_USERNAME` -> `SPRING_DATASOURCEMIGRATION_USERNAME`.
- [ENHANCEMENT] Updated the application to the latest version.

## 5.21.0

- [CHANGE] Updated the application to the latest version.
- [FEATURE] Added support for `hostAliases` configuration to customize the `/etc/hosts` file for Pods. This allows users to override DNS resolution for specific hostnames.
- [FEATURE] Added support for `customContainers` configuration to define additional containers in Pods. This enables users to add sidecar containers or custom functionality.
- [ENHANCEMENT] Updated testops-dep.yaml to dynamically render hostAliases and customContainers based on the configuration in values.yaml. This provides greater flexibility for customizing Pods.
- [BUGFIX] Fixed an issue where `inactiveUserSessionDuration` was not properly quoted in the configuration. This ensures proper handling of string values in the configuration.

## 5.20.0

- [BUGFIX] Fixed a defect in the naming pattern for analytics datasource parameters. Parameters matching `*_DATASOURCE-ANALYTICS_*` were renamed to `*_DATASOURCEANALYTICS_*` to ensure consistency with naming conventions and avoid misconfiguration.
- [CHANGE] Updated the application to the latest version.

## 5.19.0

- [CHANGE] Increased minimum Kubernetes version requirement to `>= 1.20.0-0` to guarantee compatibility with `startupProbe`.
- [FEATURE] Added `startupProbe` configuration for pods to handle slow-starting applications gracefully. The probe checks `/api/management/health/readiness` on the `http` port, ensuring the application is fully initialized before receiving traffic.

## 5.18.1

- [FEATURE] Added support for Patroni database clustering configuration in the `datasources` section. If Patroni is enabled, `dbHost` in `mainDatasource` and `analyticsDatasource` will be ignored, and database connections will be established using the Patroni hosts instead.

## 5.18.0

- [FEATURE] Added support for custom deployment labels via `labels.deployment` configuration block. This allows users to define additional labels for deployments, enhancing resource identification and management.
- [FEATURE] Added support for external secrets management in the image pull authentication configuration. Introduced a new toggle `useExternalSecret` to allow users to choose between traditional Kubernetes secrets and external secrets (e.g., External Secrets Operator). This enhances flexibility for integrations with tools like ArgoCD and HashiCorp Vault.
