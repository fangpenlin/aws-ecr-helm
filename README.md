# aws-ecr-helm
Helm chart for updating AWS ECR secret periodically

Based on this article: [Keeping AWS Registry pull credentials fresh in Kubernetes](https://medium.com/@xynova/keeping-aws-registry-pull-credentials-fresh-in-kubernetes-2d123f581ca6)

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

Then set permission to the account

```shell
kubectl create clusterrolebinding aws-ecr-agent-cluster-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=default:aws-ecr-agent
```

# TODO: should not use cluster-admin I guess

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
