# _helpers.tpl
{{- /* Validación para evitar error silencioso con volúmenes */ -}}
{{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) (not .Values.persistence.create) }}
{{- fail "❌ [storj-gateway] values.persistence.existingClaim debe estar definido si persistence.create es false." }}
{{- end }}

{{/*
Nombre base del chart
*/}}
{{- define "storj-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Nombre completo del release: release-name + chart name
*/}}
{{- define "storj-gateway.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "storj-gateway.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Etiquetas comunes recomendadas por Helm
*/}}
{{- define "storj-gateway.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "storj-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels usadas por matchLabels y el template
*/}}
{{- define "storj-gateway.selectorLabels" -}}
app: {{ include "storj-gateway.name" . }}
{{- end }}

{{/*
Nombre del serviceAccount
*/}}
{{- define "storj-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.name }}
{{- .Values.serviceAccount.name | trim }}
{{- else }}
{{- include "storj-gateway.fullname" . | trim }}
{{- end }}
{{- end }}

