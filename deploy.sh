minikube delete
sleep 10
minikube start
sleep 10
cd ../
kubectl create ns openldap
kubectl create secret generic openldap --from-literal=adminpassword=adminpassword --from-literal=users=user1admin,user2admin,user1viewer,user2viewer --from-literal=passwords=user1,user2,user1,user2 -n openldap
cd openldap
kubectl create -n openldap -f openldap-deployment.yaml
kubectl create -n openldap -f openldap-service.yaml
cd ../dex
kubectl create ns dex
helm install dex dex/dex -n dex -f dex-values.yaml
cd ../oauth2-proxy
kubectl create ns tornjak
kubectl create -f oauth2-proxy-deployment.yaml -n tornjak
kubectl create -f oauth2-proxy-service.yaml -n tornjak
cd ../openldap
kubectl get all --all-namespaces



ldapadd -x -H ldap://127.0.0.1:1389 -D "cn=admin,dc=example,dc=org" -w adminpassword -f tornjak-admin-group.ldif
ldapadd -x -H ldap://127.0.0.1:1389 -D "cn=admin,dc=example,dc=org" -w adminpassword -f tornjak-viewer-group.ldif


ldapsearch -x -H ldap://127.0.0.1:1389 -b dc=example,dc=org -D 'cn=admin,dc=example,dc=org' -w adminpassword