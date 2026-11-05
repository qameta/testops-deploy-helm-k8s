# Change log

All notable changes to this Helm chart will be documented in this file.

Entries are ordered by priority:

1. `[CHANGE]` Breaking changes
2. `[FEATURE]` New functionalities or configurations
3. `[ENHANCEMENT]` Improvements to existing features
4. `[BUGFIX]` Fixes for defects
5. `[DOCS]` Update of the documentation in `values.yaml`

## 5.28.0

- [FEATURE] Added `datasources.clientTLS` to present a client certificate (mutual TLS) to the database. The PKCS12 keystore can be sourced from a Kubernetes Secret or a CSI volume (for example, the cert-manager CSI driver) and is applied JVM-wide, so it covers all datasources.
- [FEATURE] Added `certificates.truststore` to provide the JVM trust store as a ready-made PKCS12 file (for example, from a cert-manager trust-manager Bundle `additionalFormats.pkcs12`) mounted from a Secret or a ConfigMap, without a `keytool` import step.
- [FEATURE] Added `certificates.secretName` and `certificates.key` so the PEM CA bundle can also be provided from a Secret (previously ConfigMap-only).
- [FEATURE] Added `extraVolumes` and `extraVolumeMounts` for the application container to mount additional volumes, including CSI sources.
- [FEATURE] Added `certificates.truststore.passwordSecret` and `datasources.clientTLS.keystorePasswordSecret` to source the PKCS12 password from a Kubernetes Secret (injected as an env var and referenced via `$(VAR)`), so the password is not rendered into the container spec.
- [ENHANCEMENT] The chart now fails rendering with a clear message when `datasources.clientTLS` or `certificates.truststore` is enabled without a source (Secret / ConfigMap / CSI).

## 5.27.2

- [ENHANCEMENT] Improved `S3_SHARDED` configuration by moving additional storage credentials to Kubernetes secrets and adding per-storage `awsSTS.enabled` control. This allows each additional S3 storage to either use secret-based credentials or rely on AWS STS/IAM role authentication independently.

## 5.27.1

- [FEATURE] Added support for custom secret annotations via `annotations.secret` configuration block. This allows users to define additional annotations for secrets, enhancing automation metadata or configuration for tools like ingress controllers and operators.

## 5.27.0

- [FEATURE] Added configuration support for `S3_SHARDED` storage type, allowing users to configure multiple S3 storages and map them to specific projects.

## 5.26.2

- [BUGFIX] Fixed scientific notation in the application's thread pool configuration.

## 5.26.1

- [BUGFIX] More precise configuration of the application's thread pools

## 5.26.0

- [ENHANCEMENT] maxS3Concurrency has been renamed to maxS3Connections, its default value has been changed to 100.
- [ENHANCEMENT] added a possibility to configure S3 thread pool size via `coreS3Threads` and `maxS3Threads` parameters.

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
