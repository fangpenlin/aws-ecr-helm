# aws-ecr-helm
Helm chart for updating AWS ECR secret periodically

## Setup

You need to create a service account first

```shell
kubectl create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-ecr-agent
EOF
```

Then create a secret for AWS user which has AWS ECR permissions:

 - ecr:GetAuthorizationToken
 - ecr:BatchCheckLayerAvailability
 - ecr:GetDownloadUrlForLayer
 - ecr:GetRepositoryPolicy
 - ecr:DescribeRepositories
 - ecr:ListImages
 - ecr:BatchGetImage

Like this

```shell
kubectl create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials-for-ecr
type: Opaque
stringData:
  aws-access-key-id: $AWS_ACCESS_KEY_ID
  aws-secret-access-key: $AWS_SECRET_ACCESS_KEY
EOF
```

To install with helm

```shell
helm install --name aws-ecr-agent \
    --set-string aws.aws_account=$AWS_ACCOUNT \
    --set aws.aws_region=$AWS_REGION .
```
