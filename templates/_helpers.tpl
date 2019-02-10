{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aws-ecr.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aws-ecr.fullname" -}}
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
{{- define "aws-ecr.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create container spec for updating AWS ECR secret
*/}}
{{- define "aws-ecr.container-spec" -}}
- name: kubectl
  imagePullPolicy: IfNotPresent
  image: fangpenlin/aws-kubectl:0.0.0
  env:
    - name: AWS_ACCOUNT
      value: {{ required "Value .Values.aws.aws_account is required" .Values.aws.aws_account | quote }}
    - name: AWS_REGION
      value: {{ required "Value .Values.aws.aws_region is required" .Values.aws.aws_region | quote }}
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: {{ required "Value .Values.aws.secret_name is required" .Values.aws.secret_name }}
          key: aws-access-key-id
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: {{ required "Value .Values.aws.secret_name is required" .Values.aws.secret_name }}
          key: aws-secret-access-key
    - name: DOCKER_LOGIN
      value: AWS
    - name: NAMESPACES
      value: {{ join "," .Values.namespaces | quote }}
  command:
  - "/bin/sh"
  - "-c"
  - |
    DOCKER_PASSWORD=`aws ecr get-login --region ${AWS_REGION} --registry-ids ${AWS_ACCOUNT} | cut -d' ' -f6`
    DOCKER_REGISTRY_SERVER=${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
    # ref: https://stackoverflow.com/a/27703327/25077
    for n in $(echo $NAMESPACES | sed "s/,/ /g")
    do
      kubectl delete -n $n secret aws-registry || true
      kubectl create -n $n secret docker-registry aws-registry \
        --docker-server=$DOCKER_REGISTRY_SERVER \
        --docker-username=$DOCKER_LOGIN \
        --docker-password=$DOCKER_PASSWORD \
        --docker-email=none
      kubectl patch -n $n serviceaccount default -p '{"imagePullSecrets":[{"name":"aws-registry"}]}'
    done
{{- end -}}
