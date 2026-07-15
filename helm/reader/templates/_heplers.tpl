{{- define "app.containerSecurityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
{{- end }}

{{- define "app.podSecurityContext" -}}
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
{{- end }}

{{- define "app.waitForPostgres" -}}
- name: wait-for-postgres
  image: busybox:1.35
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
  command:
    - sh
    - -c
    - until nc -z {{ .Values.dependencies.postgres.host }} {{ .Values.dependencies.postgres.port }}; do echo waiting for postgres; sleep 2; done
{{- end }}

{{- define "app.waitForBack" -}}
- name: wait-for-back
  image: busybox:1.35
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
  command:
    - sh
    - -c
    - until nc -z {{ .Values.dependencies.back.host }} {{ .Values.dependencies.back.port }}; do echo waiting for back; sleep 2; done
{{- end }}