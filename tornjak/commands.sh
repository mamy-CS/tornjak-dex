# OpenLDAP
kubectl create ns openldap
kubectl create secret generic openldap --from-literal=adminpassword=adminpassword --from-literal=users=productionadmin,productionbasic,productionconfig --from-literal=passwords=testpasswordadmin,testpasswordbasic,testpasswordconfig -n openldap
cd openldap
kubectl create -n openldap -f openldap-deployment.yaml
kubectl create -n openldap -f openldap-service.yaml

kubectl port-forward service/openldap -n openldap 1389:1389

ldapadd -x -H ldap://127.0.0.1:1389 -D "cn=admin,dc=example,dc=org" -w adminpassword -f tornjak-admin-group.ldif
ldapsearch -x -H ldap://127.0.0.1:1389 -b dc=example,dc=org -D 'cn=admin,dc=example,dc=org' -w adminpassword

# dex
cd ../dex
kubectl create ns dex
helm install dex dex/dex -n dex -f dex-values.yaml

kubectl port-forward service/dex -n dex 5556:5556

# OAuth2 Proxy
cd ../oauth2-proxy
kubectl create ns spire-server
kubectl create -f oauth2-proxy-deployment.yaml -n spire-server
kubectl create -f oauth2-proxy-service.yaml -n spire-server

kubectl port-forward service/oauth2-proxy -n spire-server 4180:4180
# Tornjak
cd ../tornjak 
kubectl create -f tornjak-frontend-deployment.yaml -n spire-server
kubectl create -f tornjak-frontend-service.yaml -n spire-server

kubectl create -f tornjak-frontend-actual-service.yaml -n spire-server
# patch
kubectl patch svc tornjak-frontend -n spire-server --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value":4180}]'
kubectl patch svc tornjak-frontend -n spire-server --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value":{"k8s-app": "oauth2-proxy"}}]'

kubectl get pods -n spire-server --watch

kubectl port-forward service/tornjak-frontend -n spire-server 9090:80


testpasswordadmin

http://oauth2-proxy.spire-server:4180/oauth2/sign_out