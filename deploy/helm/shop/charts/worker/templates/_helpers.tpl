{{- define "app.fullname" -}}
{{- .Values.fullnameOverride | default .Chart.Name }}
{{- end }}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.fullname" . }}
app.kubernetes.io/part-of: resilient-commerce
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "app.selector" -}}
app.kubernetes.io/name: {{ include "app.fullname" . }}
{{- end }}
