# Instalación

```
oscar@PRT-OMAS:~/ilba/argocd$ ./instalar_argocd.sh
```

Una vez instalado acceder via GUI y cambiar el password del admin
Saber el password del admin:

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

# Notas

## Hacer consultas a ArgoCD

Primero nos hemos de loginar

```
oscar@PRT-OMAS:~$ argocd --insecure login 172.26.0.102:443
Username: admin
Password:
'admin:login' logged in successfully
Context '172.26.0.102:443' updated
```

## Claves SSH

Ver las los know_hosts

```
oscar@PRT-OMAS:~$ argocd cert list --cert-type ssh
HOSTNAME         TYPE  SUBTYPE              INFO
gitlab.ilba.cat  ssh   ssh-rsa              SHA256:xT/6Qpk+HM8ozezun6ELLyP70OVRYzAy8LR9qnBfU5w
gitlab.ilba.cat  ssh   ssh-ed25519          SHA256:7pjr5J5aI4Le/B39xYjDlNYMm1t2POhh3qgnKnMtVQw
gitlab.ilba.cat  ssh   ecdsa-sha2-nistp256  SHA256:1w4+pxAXlzQhTppVf96DYeeVYniN5P1YbQnrrlah0ws
```

Añadir  SSH public host key

```
oscar@PRT-OMAS:~$ ssh-keyscan gitlab.ilba.cat | argocd cert add-ssh --batch
```

Posible error:

```
oscar@PRT-OMAS:~$ ssh-keyscan gitlab.ilba.cat | argocd cert add-ssh --batch
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
Enter SSH known hosts entries, one per line. Press CTRL-D when finished.
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
FATA[0000] rpc error: code = Unauthenticated desc = invalid session: signature is invalid
```

Solución:

```
oscar@PRT-OMAS:~$ argocd --insecure login 172.26.0.102:443
Username: admin
Password:
'admin:login' logged in successfully
Context '172.26.0.102:443' updated

oscar@PRT-OMAS:~$  ssh-keyscan gitlab.ilba.cat | argocd cert add-ssh --batch
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
# gitlab.ilba.cat:22 SSH-2.0-OpenSSH_8.2p1 Ubuntu-4ubuntu0.4
Enter SSH known hosts entries, one per line. Press CTRL-D when finished.
Successfully created 3 SSH known host entries
```

## Sync

### Force Sync

```
oscar@PRT-OMAS:~$ argocd app sync app-homer
```
### Sync Window

```
oscar@PRT-OMAS:~$ argocd proj windows list app-homer
ID  STATUS  KIND   SCHEDULE    DURATION  APPLICATIONS  NAMESPACES  CLUSTERS  MANUALSYNC
0   Active  allow  10 0 * * *  22h       *             -           -         Enabled
```

## Crear usuarios

```
oscar@PRT-OMAS:~$ argocd account list
NAME   ENABLED  CAPABILITIES
admin  true     login

oscar@PRT-OMAS:~$ kubectl get configmap argocd-cm -n argocd -o yaml > argocd-cm.yml
...
data:
  accounts.oscar: apiKey, login
  ...

oscar@PRT-OMAS:~$ kcaf argocd-cm.yml

oscar@PRT-OMAS:~$ argocd account list
NAME   ENABLED  CAPABILITIES
admin  true     login
oscar  true     apiKey, login

oscar@PRT-OMAS:~$ argocd account update-password --account oscar --new-password 'C@dinor1988' --current-password 'C@dinor1988'
```

# Añadir app

## app: ilba-guacamole

```
oscar@PRT-OMAS:~/ilba/argocd$ kubectl apply -f declarative/app-xxxx.yaml
```

