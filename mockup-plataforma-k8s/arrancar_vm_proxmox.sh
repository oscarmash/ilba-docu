#!/bin/bash

COLOR=$(tput setaf 4)
NC=$(tput sgr0)

clear

ssh root@172.26.0.71 -C "qm start 8230" 2> >(grep -v "Permanently added" 1>&2)
printf "\n%s\n"  "${COLOR}Server k8s-test-cp.ilba.cat is back online${NC}"

ssh root@172.26.0.71 -C "qm start 8231" 2> >(grep -v "Permanently added" 1>&2)
printf "\n%s\n"  "${COLOR}Server k8s-test-wk01.ilba.cat is back online${NC}"

ssh root@172.26.0.72 -C "qm start 8232" 2> >(grep -v "Permanently added" 1>&2)
printf "\n%s\n"  "${COLOR}Server k8s-test-wk02.ilba.cat is back online${NC}"

ssh root@172.26.0.72 -C "qm start 8233" 2> >(grep -v "Permanently added" 1>&2)
printf "\n%s\n"  "${COLOR}Server k8s-test-wk03.ilba.cat is back online${NC}"

echo ""
printf "Conectate al equipo: \033[0;33mssh 172.26.0.230\033[0m\n"
echo ""

