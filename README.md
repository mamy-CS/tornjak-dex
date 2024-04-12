# tornjak-dex
## openldap

* ```brew install openldap```
## Environment Setup
1. Create your Kind K8s cluster
    ```
    kind create cluster --name <Name of the cluster>
    ```
    or minikube 
    ```
    minikube start
    ```
1. Verify `kubectl` context matches your new Kind cluster (i.e., **kind-\<Name of the cluster>**)
   ```
   kubectl config current-context
   ```
## OpenLDAP

1. Create Namespace and Secret​
    ```
    kubectl create ns openldap
    kubectl create secret generic openldap --from-literal=adminpassword=adminpassword --from-literal=users=user1admin,user2admin,user1viewer,user2viewer --from-literal=passwords=user1,user2,user1,user2 -n openldap
    ```

1. Create Deployment​
    ```
    cd openldap
    kubectl create -n openldap -f openldap-deployment.yaml
    ```

1. Create Service
    ```
    kubectl create -n openldap -f openldap-service.yaml
    ```

1. Verify installation
    ```
    kubectl get pod -n openldap --watch
    ```

    Wait for listed pod to be *Ready/Running*

2. (In a separate terminal) Initiate *service/openldap* port-forward
    ```
    kubectl port-forward service/openldap -n openldap 1389:1389
    ```

3. Add a Group​
    ```
    ldapadd -x -H ldap://127.0.0.1:1389 -D "cn=admin,dc=example,dc=org" -w adminpassword -f tornjak-admin-group.ldif
    ldapadd -x -H ldap://127.0.0.1:1389 -D "cn=viewer,dc=example,dc=org" -w adminpassword -f tornjak-viewer-group.ldif
    ```

4. Verify LDIF Import
    ```
    ldapsearch -x -H ldap://127.0.0.1:1389 -b dc=example,dc=org -D 'cn=admin,dc=example,dc=org' -w adminpassword
    ldapsearch -x -H ldap://127.0.0.1:1389 -b dc=example,dc=org -D 'cn=viewer,dc=example,dc=org' -w adminpassword
    ```

## Dex

1. Add Dex repo to Helm
    ```
    helm repo add dex https://charts.dexidp.io
    helm repo update dex
    cd ../dex
    ```

1. Update `bindPW` in *dex-values.yaml* to match imported admin user - adminpassword

1. Install Dex via Helm
    ```
    kubectl create ns dex
    helm install dex dex/dex -n dex -f dex-values.yaml
    ```

1. Verify installation
    ```
    helm status dex -n dex
    kubectl get pod -n dex --watch
    ```

    Wait for listed pod to be *Ready/Running*

1. (In a separate terminal) Initiate *service/dex* port-forward
    ```
    kubectl port-forward service/dex -n dex 5556:5556
    ```

## OAuth2 Proxy
1. Create Deployment and Service
    ```
    cd ../oauth2-proxy
    kubectl create ns tornjak
    kubectl create -f oauth2-proxy-deployment.yaml -n tornjak
    kubectl create -f oauth2-proxy-service.yaml -n tornjak
    ```

1. Verify installation
    ```
    kubectl get pod -n tornjak --watch
    ```

    Wait for listed pods to be *Ready/Running*

1. (In a separate terminal) Initiate *service/oauth2-proxy* port-forward
    ```
    kubectl port-forward service/oauth2-proxy -n tornjak 4180:4180
    ```

1. Add *dex.dex* and *oauth2-proxy.tornjak* entry into *hosts* file:

   * Linux/macOS: `sudo vi /etc/hosts`

    Add the following entry, save, and close:
    ```
    127.0.0.1 dex.dex
    127.0.0.1 oauth2-proxy.tornjak
    ```
## Tornjak
1. Install tornjak frontend
    ```
    cd ../tornjak 
    kubectl create -f tornjak-deployment.yaml -n tornjak
    kubectl create -f tornjak-service.yaml -n tornjak
    ```

1. Verify installation
    ```
    kubectl get pods -n tornjak --watch
    ```

    Wait for listed pods to be *Ready/Running*

1. (In a separate terminal) Initiate *service/tornjak* port-forward
    ```
    kubectl port-forward service/tornjak -n tornjak 3000:80
    ```
1. Open your browser to: http://127.0.0.1:3000/ and attempt to login to your application

1. Patch the *service/tornjak* configuration to use OAuth-Proxy port and selector
    ```
    kubectl patch svc tornjak -n tornjak --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/targetPort", "value":4180}]'
    kubectl patch svc tornjak -n tornjak --type='json' -p='[{"op": "replace", "path": "/spec/selector", "value":{"k8s-app": "oauth2-proxy"}}]'
    ```

1. Stop (`Ctrl+C`) and restart *service/tornjak* port-forward
    ```
    kubectl port-forward service/tornjak -n tornjak 3000:80
    ```
1. Open your browser again to: http://127.0.0.1:3000/

1. Create Service
   ```
   kubectl create -f tornjak-actual-service.yaml -n tornjak
   ```

1. Stop (`Ctrl+C`) and restart *service/tornjak* port-forward a final time
   ```
   kubectl port-forward service/tornjak -n tornjak 3000:80
   ```

1. Open your browser again to: http://127.0.0.1:3000/

1. Tornjak Should be up!



​

​

​


​

​