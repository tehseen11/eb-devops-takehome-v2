{{- define "enterprisebot-service.name" -}}
enterprisebot-service
{{- end }}

{{- define "enterprisebot-service.fullname" -}}
{{ .Release.Name }}-{{ include "enterprisebot-service.name" . }}
{{- end }}
