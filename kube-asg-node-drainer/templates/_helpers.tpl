{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
    {{- trunc 63 .Release.Name -}}
{{- end -}}
