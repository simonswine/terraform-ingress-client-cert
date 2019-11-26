# Nginx Ingress with TLS client auth

```
# Run terraform
terraform init
terraform apply

# Setup nginx ingress
helm fetch stable/nginx-ingress --version 1.25.1
helm template nginx-ingress-1.25.1.tgz --name nginx-ingress --set controller.service.nodePorts.https=31234 --set controller.service.type=NodePort | kubectl apply -f -

# Setup demo app
kubectl apply -f ingress.yaml -f app.yaml -f secrets.yaml

# Try client cert auth
curl \
  -vi \
  --cacert ca.crt \
  --key client.key \
  --cert client.crt \
  --resolve server-cert-super-secure.cloud:31234:172.17.0.2 \
  https://server-cert-super-secure.cloud:31234/
```
