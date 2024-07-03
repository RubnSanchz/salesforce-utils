#!/bin/bash
# Despliegue de fichero srcToDeploy desde descargas de Windows a Réplica
red=$(tput setaf 1)
blue=$(tput setaf 4)
gray=$(tput setaf 059)
normal=$(tput sgr0)
  
cp /mnt/c/Users/ruben.s.gonzalez/Downloads/srcToDeploy.zip ~/AP_SALESFORCE
printf "Borramos paquete de despliegue anterior y generamos el nuevo: \n___________________________\n ${gray}"
rm -r srcToDeploy
unzip srcToDeploy.zip
rm srcToDeploy.zip
  
printf "
___________________________
${red}  !!! Verificamos que no se está ejecutando otro despliegue en destino
${normal}  Accede a ${blue}https://business-digital-team.visualstudio.com/Salesforce/_build ${normal}

___________________________
    Podemos también comprobar los despliegues en curso en SF: \n
    >> (1) Réplica:     ${blue}https://business--replica.sandbox.lightning.force.com/lightning/setup/DeployStatus/home ${normal}
    >> (2) UAT CP:      ${blue}https://business--uatcp.sandbox.lightning.force.com/lightning/setup/DeployStatus/home ${normal}
    >> (3) Pro Des:     ${blue}https://business--pdcpsva.sandbox.lightning.force.com/lightning/setup/DeployStatus/home ${normal}
${gray}sfdx data query -o business--replica -q \"SELECT Id, Status, StartDate, CompletedDate, CreatedBy.Name FROM DeployRequest WHERE Status = 'InProgress'\" -t ${normal}
___________________________
"

read -n1 -p "Continuar despliegue (1/2/3/n) ? " continue_var;
printf "\n___________________________\n"

case $continue_var in
    1)
        sfdx force:source:deploy -p srcToDeploy -u business--replica --ignorewarnings
        ;;
    2)
        sfdx force:source:deploy -p srcToDeploy -u uat_CP --ignorewarnings
        ;;
    3)
        sfdx force:source:deploy -p srcToDeploy -u pdes_QUSAC --ignorewarnings
        ;;
    *)
        echo "Ejecución finalizada sin despliegue"
        ;;
esac