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

{{- define "app.waitForKafka" -}}
- name: wait-for-kafka
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
    - until nc -z {{ .Values.dependencies.kafka.host }} {{ .Values.dependencies.kafka.port }}; do echo waiting for kafka; sleep 2; done
{{- end }}