{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "postfix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "postfix.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postfix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "postfix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "postfix.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Check if DKIM is active
*/}}
{{- define "postfix.dkimActive" -}}
    {{- if and (hasKey .Values.postfixRelay.defaultOutboundRelay "dkimDomain") (hasKey .Values.postfixRelay.defaultOutboundRelay "dkimSelector") (hasKey .Values.postfixRelay.defaultOutboundRelay "dkimKey") (hasKey .Values.postfixRelay.defaultOutboundRelay "dkimFilter") -}}
    true
    {{- else if .Values.postfixRelay.additionalOutBoundRelay -}}
        {{- range $i, $s := .Values.postfixRelay.additionalOutBoundRelay -}}
            {{- if and (hasKey $s "dkimDomain") (hasKey $s "dkimSelector") (hasKey $s "dkimKey") (hasKey $s "dkimFilter") -}}
            true
            {{- end -}}
        {{- end -}}
    {{- else -}}
    false
    {{- end -}}
{{- end -}}
