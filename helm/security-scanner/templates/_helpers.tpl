{{- define "security-scanner.name" -}}
{{- .Chart.Name }}
{{- end }}

{{- define "security-scanner.fullname" -}}
{{- .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "security-scanner.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "security-scanner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "security-scanner.selectorLabels" -}}
app.kubernetes.io/name: {{ include "security-scanner.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}