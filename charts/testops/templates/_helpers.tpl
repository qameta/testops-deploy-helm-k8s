{{/* vim: set filetype=mustache: */}}

{{- define "imagePullSecret" }}
{{- with .Values.image }}
  {{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"auth\":\"%s\"}}}" .registry .authRequired.username .authRequired.password (printf "%s:%s" .authRequired.username .authRequired.password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "testops.name" -}}
  {{- default .Chart.Name .Values.appName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testops.fullname" -}}
  {{- $name := default .Chart.Name .Values.appName -}}
  {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testops.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testops.minio.fullname" -}}
  {{- printf "%s-%s" .Release.Name "minio" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "testops.redis.fullname" -}}
{{- if .Values.redis.enabled }}
  {{- printf "%s-%s" .Release.Name "redis-master" | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- print .Values.redis.host }}
{{- end }}
{{- end -}}

{{- define "testops.secret.name" -}}
{{- if and (not .Values.externalSecrets.enabled) (not .Values.vault.enabled) }}
  {{- $secret_name := include "testops.fullname" . }}
  {{- printf $secret_name }}
{{- else }}
  {{- if .Values.externalSecrets.name }}
    {{- $secret_name := .Values.externalSecrets.name }}
    {{- printf $secret_name }}
  {{- else }}
    {{- if .Values.vault.enabled }}
      {{- $secret_name := .Values.vault.secretName }}
      {{- printf $secret_name }}
    {{ else }}
      {{- $secret_name := include "testops.fullname" . }}
      {{- printf $secret_name }}
  {{- end }}
{{- end }}
{{- end -}}
{{- end }}

{{- define "rabbitHost" }}
{{- if .Values.rabbitmq.enabled }}
  {{- printf "amqp://%s-%s:%.f" .Release.Name "rabbitmq" .Values.rabbitmq.service.ports.amqp | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- print .Values.rabbitmq.hosts }}
{{- end }}
{{- end }}

{{- define "mainDBHost" }}
{{- if .Values.postgresql.enabled }}
  {{- printf "%s-%s" .Release.Name "postgresql" | trunc 63 | trimSuffix "-" }}
{{- else }}
  {{- print .Values.datasources.mainDatasource.dbHost }}
{{- end }}
{{- end }}

{{- define "mainDBPort" }}
{{- if .Values.postgresql.enabled }}
  {{- print "5432"}}
{{- else }}
  {{- printf "%.f" .Values.datasources.mainDatasource.dbPort }}
{{- end }}
{{- end }}

{{- define "mainDBName" }}
{{- if .Values.postgresql.enabled }}
  {{- print "testops"}}
{{- else }}
  {{- print .Values.datasources.mainDatasource.dbName }}
{{- end }}
{{- end }}

{{- define "mainDBSSL" }}
{{- if .Values.postgresql.enabled }}
  {{- print "disable" }}
{{- else }}
  {{- print .Values.datasources.mainDatasource.sslMode }}
{{- end }}
{{- end }}

{{- define "analyticsDBHost" }}
  {{- print .Values.datasources.analyticsDatasource.dbHost }}
{{- end }}

{{- define "analyticsDBPort" }}
  {{- printf "%.f" .Values.datasources.analyticsDatasource.dbPort }}
{{- end }}

{{- define "analyticsDBName" }}
  {{- print .Values.datasources.analyticsDatasource.dbName }}
{{- end }}

{{- define "analyticsDBSSL" }}
  {{- print .Values.datasources.analyticsDatasource.sslMode }}
{{- end }}

{{- define "renderCommonEnvs" }}
  - name: ALLURE_MAIL_ROOT
    value: "{{ .Values.email }}"
  - name: SPRING_PROFILES_ACTIVE
    value: kubernetes
  - name: ALLURE_ENDPOINT
    value: "{{ ternary "https" "http" .Values.network.tls.enabled }}://{{ .Values.instanceFqdn }}"
  - name: SERVER_PORT
    value: "{{ .Values.port }}"
  - name: MANAGEMENT_PROMETHEUS_METRICS_EXPORT_ENABLED
    value: 'true'
  - name: MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE
    value: "{{ .Values.monitoring.management.expose }}"
  - name: MANAGEMENT_ENDPOINT_HEALTH_CACHE_TIME-TO-LIVE
    value: "{{ .Values.monitoring.management.cacheTTL }}"
  - name: MANAGEMENT_HEALTH_DISKSPACE_ENABLED
    value: "false"
  - name: MANAGEMENT_HEALTH_KUBERNETES_ENABLED
    value: "false"
  - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK
    value: "{{ .Values.logging.baseLogLevel }}"
  - name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY
    value: "{{ .Values.logging.securityLogLevel }}"
  - name: LOGGING_LEVEL_COM_ZAXXER_HIKARI
    value: "{{ .Values.logging.hikariLogLevel }}"
  - name: LOGGING_LEVEL_IO_QAMETA_ALLURE_REPORT_ISSUE_LISTENER
    value: "error"
  - name: SPRING_OUTPUT_ANSI_ENABLED
    value: "never"
  - name: SERVER_ERROR_INCLUDE_STACKTRACE
    value: "always"
  - name: SPRING_CLOUD_DISCOVERY_CLIENT_HEALTH_INDICATOR_ENABLED
    value: "false"
  - name: ALLURE_JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "jwtSecret"
  - name: ALLURE_SECURE
    value: "{{ .Values.network.tls.secureCookie }}"
  - name: ALLURE_REGISTRATION_ENABLED
    value: "{{ .Values.registrationEnabled }}"
  - name: ALLURE_REGISTRATION_AUTOAPPROVE
    value: "{{ .Values.autoApprove }}"
  - name: ALLURE_JWT_ACCESS_TOKEN_VALIDITY_SECONDS
    value: "{{ .Values.bearerTokenExpirationAfter }}"
  - name: ALLURE_LOGIN_PRIMARY
    value: {{ .Values.auth.primary }}
  - name: ALLURE_LOGIN_MAIL_DEFAULTROLE
    value: {{ .Values.auth.defaultRole }}
  - name: TZ
    value: "{{ .Values.timeZone }}"
  - name: JAVA_TOOL_OPTIONS
{{- if .Values.proxy.enabled }}
    value: "{{ template "renderJavaOpts" .Values.resources.limits.memory }} -Dhttps.proxyHost={{ .Values.proxy.proxyHost }} -Dhttp.proxyHost={{ .Values.proxy.proxyHost }} -Dhttps.proxyPort={{ .Values.proxy.proxyPort }} -Dhttp.proxyPort={{ .Values.proxy.proxyPort }} -Dspring.mail.properties.mail.smtp.proxy.host={{ .Values.proxy.proxyHost }} -Dspring.mail.properties.mail.smtp.proxy.port={{ .Values.proxy.proxyPort }} -Dhttps.nonProxyHosts={{ .Values.proxy.nonProxy }} -Dhttp.nonProxyHosts={{ .Values.proxy.nonProxy }} -Djavax.net.ssl.trustStore=/etc/pki/ca-trust/extracted/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
{{- else if .Values.certificates.configmapName }}
    value: "{{ template "renderJavaOpts" .Values.resources.limits.memory }} -Djavax.net.ssl.trustStore=/etc/pki/ca-trust/extracted/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
{{- else }}
    value: "{{ template "renderJavaOpts" .Values.resources.limits.memory }}"
{{- end }}
{{- if .Values.proxy.enabled }}
  - name: http_proxy
    value: "http://{{ .Values.proxy.proxyHost }}:{{ .Values.proxy.proxyPort }}"
  - name: HTTP_PROXY
    value: "http://{{ .Values.proxy.proxyHost }}:{{ .Values.proxy.proxyPort }}"
  - name: https_proxy
    value: "http://{{ .Values.proxy.proxyHost }}:{{ .Values.proxy.proxyPort }}"
  - name: HTTPS_PROXY
    value: "http://{{ .Values.proxy.proxyHost }}:{{ .Values.proxy.proxyPort }}"
  - name: no_proxy
    value: "{{ .Values.proxy.noProxy }}"
  - name: NO_PROXY
    value: "{{ .Values.proxy.noProxy }}"
{{- end }}
{{- if .Values.certificates.endpoints }}
  - name: TLS_ENDPOINTS
    value: "{{ .Values.certificates.endpoints }}"
{{- end }}
{{- if .Values.certificates.staticCerts }}
  - name: STATIC_CERTS
    value: "{{ join "," .Values.certificates.staticCerts }}"
{{- end }}

{{- end }}


{{- define "renderLDAPEnvs" }}
  - name: ALLURE_LOGIN_LDAP_ENABLED
    value: "{{ .Values.auth.ldap.enabled }}"
  - name: ALLURE_LOGIN_LDAP_DEFAULTROLE
    value: {{ .Values.auth.defaultRole }}
  - name: ALLURE_LOGIN_LDAP_REFERRAL
    value: "{{ .Values.auth.ldap.referral }}"
  - name: ALLURE_LOGIN_LDAP_LOWERCASEUSERNAMES
    value: "{{ .Values.auth.ldap.usernamesToLowercase }}"
  - name: ALLURE_LOGIN_LDAP_PASSWORDATTRIBUTE
    value: "{{ .Values.auth.ldap.passwordAttribute }}"
  - name: ALLURE_LOGIN_LDAP_URL
    value: "{{ .Values.auth.ldap.url }}"
{{- if .Values.auth.ldap.user.dnPatterns }}
  - name: ALLURE_LOGIN_LDAP_USERDNPATTERNS
    value: "{{ .Values.auth.ldap.user.dnPatterns }}"
{{- end }}
  - name: ALLURE_LOGIN_LDAP_USERSEARCHBASE
    value: "{{ .Values.auth.ldap.user.searchBase }}"
  - name: ALLURE_LOGIN_LDAP_USERSEARCHFILTER
    value: "{{ .Values.auth.ldap.user.searchFilter }}"
  - name: ALLURE_LOGIN_LDAP_UIDATTRIBUTE
    value: "{{ .Values.auth.ldap.uidAttribute }}"
  - name: ALLURE_LOGIN_LDAP_SYNCROLES
    value: "{{ .Values.auth.ldap.syncRoles }}"
{{- if .Values.auth.ldap.syncRoles }}
  - name: ALLURE_LOGIN_LDAP_GROUPSEARCHBASE
    value: "{{ .Values.auth.ldap.group.searchBase }}"
  - name: ALLURE_LOGIN_LDAP_GROUPSEARCHFILTER
    value: "{{ .Values.auth.ldap.group.searchFilter }}"
  - name: ALLURE_LOGIN_LDAP_GROUPROLEATTRIBUTE
    value: "{{ .Values.auth.ldap.group.roleAttribute }}"
  - name: ALLURE_LOGIN_LDAP_GROUPAUTHORITIES_ROLEUSERGROUPS
    value: "{{ .Values.auth.ldap.userGroupName }}"
  - name: ALLURE_LOGIN_LDAP_GROUPAUTHORITIES_ROLEADMINGROUPS
    value: "{{ .Values.auth.ldap.adminGroupName }}"
{{- end }}
  - name: ALLURE_LOGIN_LDAP_USERDN
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: ldapUser
  - name: ALLURE_LOGIN_LDAP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: ldapPass
{{- end }}


{{- define "renderSAMLEnvs" }}
  - name: ALLURE_LOGIN_SAML2_ENABLED
    value: "true"
  - name: ALLURE_LOGIN_SAML2_ID
    value: {{ .Values.auth.saml.id }}
  - name: ALLURE_LOGIN_SAML2_ENTITY_ID
    value: "{{ .Values.auth.saml.entityId }}"
  - name: ALLURE_LOGIN_SAML2_ACS_URL
    value: "{{ .Values.auth.saml.acsUrl }}"
  - name: ALLURE_LOGIN_SAML2_METADATA_URL
    value: "{{ .Values.auth.saml.identityProviderMetadataUri }}"
  - name: ALLURE_LOGIN_SAML2_DEFAULTROLE
    value: {{ .Values.auth.defaultRole }}
  - name: ALLURE_LOGIN_SAML2_FIRSTNAMEATTRIBUTE
    value: {{ .Values.auth.saml.firstNameAttribute }}
  - name: ALLURE_LOGIN_SAML2_LASTNAMEATTRIBUTE
    value: {{ .Values.auth.saml.lastNameAttribute }}
  - name: ALLURE_LOGIN_SAML2_EMAILATTRIBUTE
    value: {{ .Values.auth.saml.emailAttribute }}
  - name: ALLURE_LOGIN_SAML2_SYNCROLES
    value: "{{ .Values.auth.saml.syncRoles }}"
{{- if .Values.auth.saml.syncRoles }}
  - name: ALLURE_LOGIN_SAML2_GROUPROLEATTRIBUTE
    value: {{ .Values.auth.saml.groups.groupRoleAttribute }}
  - name: ALLURE_LOGIN_SAML2_GROUPAUTHORITIES_ROLEUSERGROUPS
    value: "{{ .Values.auth.saml.groups.roleUserGroups }}"
  - name: ALLURE_LOGIN_SAML2_GROUPAUTHORITIES_ROLEADMINGROUPS
    value: "{{ .Values.auth.saml.groups.roleAdminGroups }}"
{{- end }}
{{- end }}

{{- define "renderOPENIDEnvs" }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_CLIENTNAME
    value: {{ .Values.auth.openid.clientName }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_CLIENTID
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: openIdClientId
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_CLIENTSECRET
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: openIdClientSecret
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_REDIRECTURI
    value: {{ .Values.auth.openid.redirectUri }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_SCOPE
    value: {{ .Values.auth.openid.scope }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_AUTHORIZATIONGRANTTYPE
    value: {{ .Values.auth.openid.authorizationGrantType }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_AUTHORIZATIONURI
    value: {{ .Values.auth.openid.authorizationUri }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_USERNAMEATTRIBUTE
    value: {{ .Values.auth.openid.usernameAttribute }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_{{ .Values.auth.openid.providerName | upper }}_PROVIDER
    value: {{ .Values.auth.openid.providerName }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_JWKSETURI
    value: {{ .Values.auth.openid.jwksSetUri }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_TOKENURI
    value: {{ .Values.auth.openid.tokenUri }}
  - name: ALLURE_LOGIN_OPENID_DEFAULTROLE
    value: {{ .Values.auth.openid.defaultRole }}
{{- if .Values.auth.openid.userinfoUri }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_USERINFOURI
    value: {{ .Values.auth.openid.userinfoUri }}
{{- end }}
{{- if .Values.auth.openid.issuerUri }}
  - name: SPRING_SECURITY_OAUTH2_CLIENT_PROVIDER_{{ .Values.auth.openid.providerName | upper }}_ISSUERURI
    value: {{ .Values.auth.openid.issuerUri }}
{{- end }}
{{- if .Values.auth.openid.firstNameAttribute }}
  - name: ALLURE_LOGIN_OPENID_FIRSTNAMEATTRIBUTE
    value: {{ .Values.auth.openid.firstNameAttribute }}
{{- end }}
{{- if .Values.auth.openid.lastNameAttribute }}
  - name: ALLURE_LOGIN_OPENID_LASTAMEATTRIBUTE
    value: {{ .Values.auth.openid.lastNameAttribute }}
{{- end }}
{{- if .Values.auth.openid.syncRoles }}
  - name: ALLURE_LOGIN_OPENID_SYNCROLES
    value: "true"
  - name: ALLURE_LOGIN_OPENID_GROUPROLEATTRIBUTE
    value: {{ .Values.auth.openid.groupRoleAttribute }}
  - name: ALLURE_LOGIN_OPENID_GROUPAUTHORITIES_ROLEUSERGROUPS
    value: {{ .Values.auth.openid.roleUserGroups }}
  - name: ALLURE_LOGIN_OPENID_GROUPAUTHORITIES_ROLEADMINGROUPS
    value: {{ .Values.auth.openid.roleAdminGroups }}
{{- else }}
  - name: ALLURE_LOGIN_OPENID_SYNCROLES
    value: "false"
{{- end }}
{{- end }}

{{- define "renderCryptoEnvs" }}
  - name: ALLURE_CRYPTO_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "cryptoPass"
{{- end }}


{{- define "renderDataBaseEnvs" }}
  - name: SPRING_DATASOURCE_URL
{{- if .Values.datasources.patroni.enabled }}
    value: "jdbc:postgresql://{{ join "," .Values.datasources.patroni.hosts }}/{{ .Values.datasources.mainDatasource.dbName }}?targetServerType={{ .Values.datasources.patroni.targetServerType }}"
{{- else if or (eq .Values.datasources.mainDatasource.sslMode "require") (eq .Values.datasources.mainDatasource.sslMode "verify-ca") (eq .Values.datasources.mainDatasource.sslMode "verify-full") }}
    value: "jdbc:postgresql://{{ template "mainDBHost" . }}:{{ template "mainDBPort" . }}/{{ template "mainDBName" . }}?sslmode={{ template "mainDBSSL" . }}&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory"
{{- else }}
    value: "jdbc:postgresql://{{ template "mainDBHost" . }}:{{ template "mainDBPort" . }}/{{ template "mainDBName" . }}?sslmode={{ template "mainDBSSL" . }}"
{{- end }}
{{- if or (eq .Values.datasources.mainDatasource.sslMode "require") (eq .Values.datasources.mainDatasource.sslMode "verify-ca") (eq .Values.datasources.mainDatasource.sslMode "verify-full") }}
  - name: TLS_DB_ENDPOINTS
    value: "{{ .Values.datasources.mainDatasource.dbHost}}:{{ .Values.datasources.mainDatasource.dbPort }}"
{{- end }}
  - name: SPRING_DATASOURCE_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbUser"
  - name: SPRING_DATASOURCE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbPass"
  - name: SPRING_DATASOURCEMIGRATION_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbUser"
  - name: SPRING_DATASOURCEMIGRATION_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbPass"
  - name: SPRING_DATASOURCE_HIKARI_MAXIMUMPOOLSIZE
    value: "{{ .Values.datasources.mainDatasource.appMaxDBConnection }}"
  - name: SPRING_DATASOURCE_HIKARI_CONNECTIONTIMEOUT
    value: "{{ .Values.datasources.mainDatasource.appConnectionTimeout }}"
  - name: SPRING_DATASOURCEMIGRATION_HIKARI_MAXIMUM_POOL_SIZE
    value: {{ .Values.datasources.migrationDatasource.maxDBMigrationConn | quote }}
  - name: SPRING_DATASOURCEMIGRATION_HIKARI_MINIMUM_IDLE
    value: {{ .Values.datasources.migrationDatasource.minDBMigrationIdle | quote }}
  - name: ALLURE_MIGRATION_TASK_SCHEDULER_POOL_SIZE
    value: {{ .Values.datasources.migrationDatasource.migrationSchedulerPoolSize | quote }}

{{- if .Values.datasources.uploaderDatasource.enabled }}
  - name: SPRING_DATASOURCEUPLOADER_URL
{{- if or (eq .Values.datasources.mainDatasource.sslMode "require") (eq .Values.datasources.mainDatasource.sslMode "verify-ca") (eq .Values.datasources.mainDatasource.sslMode "verify-full") }}
    value: "jdbc:postgresql://{{ template "mainDBHost" . }}:{{ template "mainDBPort" . }}/{{ template "mainDBName" . }}?sslmode={{ template "mainDBSSL" . }}&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory"
{{- else }}
    value: "jdbc:postgresql://{{ template "mainDBHost" . }}:{{ template "mainDBPort" . }}/{{ template "mainDBName" . }}?sslmode={{ template "mainDBSSL" . }}"
{{- end }}
  - name: SPRING_DATASOURCEUPLOADER_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbUser"
  - name: SPRING_DATASOURCEUPLOADER_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "testopsDbPass"
  - name: SPRING_DATASOURCEUPLOADER_HIKARI_MAXIMUMPOOLSIZE
    value: "{{ .Values.datasources.uploaderDatasource.appMaxDBConnection }}"
  - name: SPRING_DATASOURCEUPLOADER_HIKARI_CONNECTIONTIMEOUT
    value: "{{ .Values.datasources.uploaderDatasource.appConnectionTimeout }}"
{{- end }}

{{- if .Values.datasources.analyticsDatasource.enabled }}
  - name: SPRING_DATASOURCEANALYTICS_URL
{{- if .Values.datasources.patroni.enabled }}
    value: "jdbc:postgresql://{{ join "," .Values.datasources.patroni.hosts }}/{{ .Values.datasources.analyticsDatasource.dbName }}?targetServerType={{ .Values.datasources.patroni.targetServerType }}"
{{- else if or (eq .Values.datasources.analyticsDatasource.sslMode "require") (eq .Values.datasources.analyticsDatasource.sslMode "verify-ca") (eq .Values.datasources.analyticsDatasource.sslMode "verify-full") }}
    value: "jdbc:postgresql://{{ template "analyticsDBHost" . }}:{{ template "analyticsDBPort" . }}/{{ template "analyticsDBName" . }}?sslmode={{ template "analyticsDBSSL" . }}&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory&readOnly=true"
{{- else }}
    value: "jdbc:postgresql://{{ template "analyticsDBHost" . }}:{{ template "analyticsDBPort" . }}/{{ template "analyticsDBName" . }}?sslmode={{ template "analyticsDBSSL" . }}&readOnly=true"
{{- end }}
  - name: SPRING_DATASOURCEANALYTICS_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "analyticsDbUser"
  - name: SPRING_DATASOURCEANALYTICS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "analyticsDbPass"
  - name: SPRING_DATASOURCEANALYTICS_HIKARI_MAXIMUMPOOLSIZE
    value: "{{ .Values.datasources.analyticsDatasource.appMaxDBConnection }}"
  - name: SPRING_DATASOURCEANALYTICS_HIKARI_CONNECTIONTIMEOUT
    value: "{{ .Values.datasources.analyticsDatasource.appConnectionTimeout }}"
{{- end }}

{{- end }}

{{- define "renderRabbitMQEnvs" }}
  - name: SPRING_RABBITMQ_ADDRESSES
    value: {{ template "rabbitHost" . }}
  - name: SPRING_RABBITMQ_VIRTUAL_HOST
    value: {{ .Values.rabbitmq.vhost }}
  - name: SPRING_RABBITMQ_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "rabbitUser"
  - name: SPRING_RABBITMQ_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "rabbitPass"
  - name: SPRING_RABBITMQ_LISTENER_SIMPLE_MAXCONCURRENCY
    value: "{{ .Values.maxConcurrency }}"
  - name: ALLURE_UPLOAD_PARSE_CONSUMERSPERQUEUE
    value: {{ .Values.parseConsumers | quote }}
  - name: ALLURE_UPLOAD_STORE_CONSUMERSPERQUEUE
    value: {{ .Values.storeConsumers | quote }}
{{- end }}


{{- define "renderRedisEnvs" }}
  - name: SPRING_SESSION_STORE_TYPE
    value: "REDIS"
  - name: ALLURE_REDIS_SESSIONTTL
    value: {{ .Values.inactiveUserSessionDuration | quote }}
{{- if .Values.redis.sentinel.enabled }}
  - name: SPRING_REDIS_SENTINEL_NODES
    value: "{{ .Values.redis.sentinel.nodes }}"
  - name: SPRING_REDIS_SENTINEL_MASTER
    value: "{{ .Values.redis.sentinel.masterSet }}"
  - name: SPRING_REDIS_SENTINEL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "redisPass"
{{- else }}
  - name: SPRING_DATA_REDIS_HOST
    value: "{{ template "testops.redis.fullname" . }}"
  - name: SPRING_DATA_REDIS_PORT
    value: "{{ .Values.redis.port }}"
  - name: SPRING_DATA_REDIS_DATABASE
    value: "{{ .Values.redis.database }}"
  - name: SPRING_DATA_REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "redisPass"
{{- end }}
{{- if .Values.redis.namespace }}
  - name: ALLURE_REDIS_NAMESPACE
    value: "{{ .Values.redis.namespace }}"
{{- end }}
{{- end }}


{{- define "renderS3Envs" }}
  - name: ALLURE_BLOBSTORAGE_TYPE
    value: {{ .Values.storage.type }}
  - name: ALLURE_BLOBSTORAGE_MAXCONCURRENCY
    value: "{{ .Values.maxS3Concurrency }}"
{{- if .Values.storage.s3.advancedS3SDK.enabled }}
  - name: ALLURE_BLOBSTORAGE_BULKREMOVESUPPORTED
    value: {{ .Values.storage.s3.advancedS3SDK.bulkRemoveSupported | quote}}
  - name: ALLURE_BLOBSTORAGE_MOVESUPPORTED
    value: {{ .Values.storage.s3.advancedS3SDK.moveSupported | quote}}
  - name: ALLURE_BLOBSTORAGE_COPYSUPPORTED
    value: {{ .Values.storage.s3.advancedS3SDK.copySupported | quote}}
{{- end }}
  - name: ALLURE_BLOBSTORAGE_S3_ENDPOINT
{{- if .Values.minio.enabled }}
    value: http://{{ template "testops.minio.fullname" . }}:{{ .Values.minio.service.ports.api }}
  - name: ALLURE_BLOBSTORAGE_S3_PATHSTYLEACCESS
    value: "true"
{{- else }}
    value: {{ .Values.storage.s3.endpoint }}
  - name: ALLURE_BLOBSTORAGE_S3_PATHSTYLEACCESS
    value: "{{ .Values.storage.s3.pathstyle }}"
{{- end }}
  - name: ALLURE_BLOBSTORAGE_S3_BUCKET
{{- if .Values.minio.enabled }}
    value: {{ .Values.minio.defaultBuckets }}
{{- else }}
    value: {{ .Values.storage.s3.bucket }}
{{- end }}
  - name: ALLURE_BLOBSTORAGE_S3_REGION
{{- if .Values.minio.enabled }}
    value: {{ .Values.minio.defaultRegion }}
{{- else }}
    value: {{ .Values.storage.s3.region}}
{{- end }}
{{- if not .Values.storage.awsSTS.enabled }}
  - name: ALLURE_BLOBSTORAGE_S3_ACCESSKEY
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "s3AccessKey"
  - name: ALLURE_BLOBSTORAGE_S3_SECRETKEY
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "s3SecretKey"
{{- end }}
{{- if .Values.storage.s3.serverSideEncryption.enabled }}
  - name: ALLURE_BLOB_STORAGE_S3_SERVER_SIDE_ENCRYPTION
    value: {{ .Values.storage.s3.serverSideEncryption.type | quote }}
{{- if .Values.storage.s3.serverSideEncryption.keyId }}
  - name: ALLURE_BLOB_STORAGE_S3_KMS_KEY_ID
    value: {{ .Values.storage.s3.serverSideEncryption.keyId | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "renderFSEnvs" }}
  - name: ALLURE_BLOBSTORAGE_TYPE
    value: FILE_SYSTEM
  - name: ALLURE_BLOBSTORAGE_FILESYSTEM_DIRECTORY
    value: "{{ .Values.storage.csi.mountPoint }}"
{{- end }}

{{- define "renderSMTPEnvs" }}
  - name: SPRING_MAIL_HOST
    value: {{ .Values.smtp.host }}
  - name: SPRING_MAIL_PORT
    value: "{{ .Values.smtp.port }}"
  - name: SPRING_MAIL_USERNAME
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "smtpUsername"
  - name: ALLURE_MAIL_FROM
    value: {{ .Values.smtp.from }}
  - name: SPRING_MAIL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: {{ template "testops.secret.name" . }}
        key: "smtpPassword"
  - name: SPRING_MAIL_PROPERTIES_MAIL_SMTP_AUTH
    value: {{ .Values.smtp.authEnabled | quote }}
  - name: SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_ENABLE
    value: {{ .Values.smtp.startTLSEnabled | quote }}
  - name: SPRING_MAIL_PROPERTIES_MAIL_SMTP_STARTTLS_REQUIRED
    value: {{ .Values.smtp.startTLSRequired | quote }}
  - name: SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE
    value: {{ .Values.smtp.sslEnabled | quote }}
  - name: SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST
    value: {{ .Values.smtp.sslTrust | quote }}
{{- end }}

{{- define "renderWidgetsCache" }}
  - name: ALLURE_CACHETTL_ENABLED
    value: {{ .Values.widgetsCache.enabled | quote }}
  - name: ALLURE_CACHETTL_BYDEFAULT
    value: {{ .Values.widgetsCache.byDefault }}
  - name: ALLURE_CACHETTL_WIDGETS_AUTOMATIONTREND
    value: {{ .Values.widgetsCache.widgets.automationTrend }}
  - name: ALLURE_CACHETTL_WIDGETS_TRCOMPLEXTREND
    value: {{ .Values.widgetsCache.widgets.trComplexTrend }}
  - name: ALLURE_CACHETTL_WIDGETS_TRSTATISTICTREND
    value: {{ .Values.widgetsCache.widgets.trStatisticTrend }}
  - name: ALLURE_CACHETTL_WIDGETS_LAUNCHDURATIONHISTOGRAM
    value: {{ .Values.widgetsCache.widgets.launchDurationHistogram }}
  - name: ALLURE_CACHETTL_WIDGETS_ANALYTICPIECHART
    value: {{ .Values.widgetsCache.widgets.analyticPieChart }}
  - name: ALLURE_CACHETTL_WIDGETS_PROJECTMETRICTREND
    value: {{ .Values.widgetsCache.widgets.projectMetricTrend }}
  - name: ALLURE_CACHETTL_WIDGETS_TCLASTRESULT
    value: {{ .Values.widgetsCache.widgets.tcLastResult }}
{{- range $key, $value := .Values.widgetsCache.widgetsCustom }}
  - name: ALLURE_CACHETTL_WIDGETSCUSTOM_{{ $key }}
    value: {{ $value }}
{{- end }}
{{- end }}

{{- define "calculateMemory" }}
  {{- $v := . }}
  {{- if not $v }}
    {{- print "-Xms256M -Xmx768M" }}
  {{- end }}
  {{- $unit := "M" }}
  {{- $xms := 256 }}
  {{- $xmx := 768 }}
  {{- if $v | hasSuffix "Mi" }}
    {{- $xms = div ($v | trimSuffix "Mi" ) 4 }}
    {{- $xmx = mul $xms 3 }}
  {{- else if $v | hasSuffix "Gi" }}
    {{- if le ($v | trimSuffix "Gi" | atoi ) 4 }}
      {{- $unit = "M" }}
      {{- $xms = div (mul ($v | trimSuffix "Gi") 1024) 4 }}
      {{- $xmx = mul $xms 3 }}
    {{- else }}
      {{- $unit = "G" }}
      {{- $xms = div ($v | trimSuffix "Gi" ) 4 }}
      {{- $xmx = mul $xms 3 }}
    {{- end }}
  {{- end }}
  {{- if gt ($v | trimSuffix "Gi" | atoi ) 12 }}
    {{- printf "-XX:+UseG1GC -XX:+UseStringDeduplication -Xms%d%s -Xmx%d%s" $xms $unit $xmx $unit }}
  {{- else }}
    {{- printf "-XX:+UseParallelGC -Xms%d%s -Xmx%d%s" $xms $unit $xmx $unit }}
  {{- end }}
{{- end }}

{{- define "renderJavaOpts" }}
  {{- $v := . }}
  {{- $memString := include "calculateMemory" $v }}
  {{- printf "-XX:AdaptiveSizePolicyWeight=50 -XX:+UseTLAB -XX:GCTimeRatio=15 -XX:MinHeapFreeRatio=40 -XX:MaxHeapFreeRatio=70 -XX:-PrintFlagsFinal %s" $memString }}
{{- end }}

{{- define "getImageRegistry" }}
{{- if .Values.image.imageName }}
  {{- printf "%s/%s/%s" .Values.image.registry .Values.image.repository .Values.image.imageName }}
{{- else }}
  {{- printf "%s/" .Values.image.repository }}
{{- end }}
{{- end }}
