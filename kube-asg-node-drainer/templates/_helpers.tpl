{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kube-asg-node-drainer.name" -}}
    {{- trunc 63 .Release.Name -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kube-asg-node-drainer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kube-asg-node-drainer.labels" -}}
app.kubernetes.io/name: {{ template "kube-asg-node-drainer.name" . }}
helm.sh/chart: {{ template "kube-asg-node-drainer.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.podLabels }}
{{ toYaml .Values.podLabels }}
{{- end }}
{{- end -}}

{{/* matchLabels */}}
{{- define "kube-asg-node-drainer.matchLabels" -}}
app.kubernetes.io/name: {{ template "kube-asg-node-drainer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}