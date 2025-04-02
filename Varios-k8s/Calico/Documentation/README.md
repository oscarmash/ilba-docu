# Index:

* [Show network policies](#id10)
* [Delete a network policy](#id20)
* [View details for a network policy](#id30)

# Show network policies <div id='id10' />

```
root@ilimit-paas-k8s-pre-cp01:~# calicoctl get NetworkPolicy -A -o wide
NAMESPACE              NAME                                                  ORDER   SELECTOR
ca-carrefour-website   ca-carrefour-website-advanced-stack-netpolicy-allow   10
ca-carrefour-website   ca-carrefour-website-advanced-stack-netpolicy-deny    20
...
```

# Delete a network policy <div id='id20' />

```
root@ilimit-paas-k8s-pre-cp01:~# calicoctl delete policy $POLICY_NAME --namespace=$NAMESPACE
```

# View details for a network policy <div id='id20' />

```
root@ilimit-paas-k8s-pre-cp01:~# calicoctl get NetworkPolicy -o yaml $POLICY_NAME --namespace $NAMESPACE
```