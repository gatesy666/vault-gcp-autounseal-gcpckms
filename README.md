# Vault GCP Auto Unseal - gcpckms

### Create Vault certs

```
cd tf-tls
terraform init
terraform plan
terraform apply
cd ..
```

### GCP project setup

```
gcloud auth application-default login
cd tf-gcp-resources 
```

Edit vars as required

```
terraform init
terraform plan
terraform apply
```

### Create private cluster 

Master auth set to your wan ip (need to setup nat for helm install, bump up num-nodes as required, and add service account)

```
gcloud container clusters create vault \
    --enable-autorepair \
    --enable-autoupgrade \
    --enable-ip-alias \
    --machine-type n1-standard-1 \
    --num-nodes 1 \
    --region europe-west2 \
    --scopes cloud-platform \
    --enable-private-nodes \
    --master-ipv4-cidr 172.16.0.32/28 \
    --enable-master-authorized-networks \
    --master-authorized-networks *.*.*.*/32 \
    --service-account vault-server@vault-gke-******.iam.gserviceaccount.com
```

```
gcloud compute routers create nat-router \
    --network default \
    --region europe-west2 

gcloud compute routers nats create nat-config \
    --router-region europe-west2 \
    --router nat-router \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

Shouldn't have to run below unless you switched to another cluster

```
gcloud container clusters get-credentials vault \
    --region europe-west2 \
    --project vault-gke-******
```
    
### Create secrets

```
cd ..
kubectl create secret generic tls-secret --from-file=tls.crt=./tf-tls/vault_cert.pem --from-file=tls.key=./tf-tls/vault_private_key.pem --from-file=ca.crt=./tf-tls/vault_ca_cert.pem
```



### Install vault

Edit auto unseal block as required

```
helm upgrade --install vault hashicorp/vault -f ./overrides.yaml
```

*** OR ***

```
helm upgrade --install vault hashicorp/vault -f ./overrides-global-keyring.yaml
```

### Init Vault - will auto unseal

```
kubectl exec vault-0 -- vault operator init -format=json > cluster-keys.json
```

### Join follower nodes to raft

Repeat for all nodes

```
kubectl exec vault-1 --  /bin/sh -c 'vault operator raft join -leader-ca-cert="$(cat /vault/userconfig/tls-secret/ca.crt)" --address "https://vault-1.vault-internal:8200" "https://vault-0.vault-internal:8200"'
kubectl exec vault-2 --  /bin/sh -c 'vault operator raft join -leader-ca-cert="$(cat /vault/userconfig/tls-secret/ca.crt)" --address "https://vault-2.vault-internal:8200" "https://vault-0.vault-internal:8200"'
```

### Check status

```
CLUSTER_ROOT_TOKEN=$(cat cluster-keys.json | jq -r ".root_token")
kubectl exec vault-0 -- vault login $CLUSTER_ROOT_TOKEN
kubectl exec vault-0 -- vault operator raft list-peers

kubectl exec vault-1 -- vault status
kubectl exec vault-2 -- vault status
```


