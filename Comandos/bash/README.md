* [Replace](#id1)

## Replace <div id='id1' />

En este directorio buscame recursivamente todos los archivos que contengan _targetRevision: master_ i substituyes la palabra: _targetRevision: master_ por _targetRevision: main_

```
$ LANG=C grep -r 'targetRevision: main' *
advanced-clients/ilimit-syspass/helm-chart.yaml:      targetRevision: main
advanced-clients/ilimit-syspass/helm-chart.yaml:      targetRevision: main
advanced-clients/zack-provespre/helm-chart.yaml:      targetRevision: main
```

```
$ for i in `grep -r 'targetRevision: master' * | awk -F ':' '{print $1}'`; do sed -i 's#targetRevision: master#targetRevision: main#g' $i; done
```