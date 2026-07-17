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
  resources:
    requests:
      cpu: 50m
      memory: 32Mi
    limits:
      cpu: 100m
      memory: 64Mi
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
    - |
      until wget -qO- http://{{ .Values.dependencies.back.host }}:{{ .Values.dependencies.back.managementPort }}/health 2>/dev/null | grep -q '"status":"UP"'; do
        echo "Waiting for Back to be healthy..."
        sleep 5
      done
      echo "Back is healthy"
{{- end }}