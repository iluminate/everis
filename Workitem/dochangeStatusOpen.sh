#!/bin/bash
#Carga de Variables de configuracion
DIR=/home/fallas/SHELLS/operacionales/Workitem
. ${DIR}/bin/.varset
. ${DIR}/bin/.functionset

#Variables
COMMAND="-update repository=$RTCURL user=$RTCUSER password=$RTCPASS id=$1 internalState=Documentacion.state.s2"

update(){
	wcl $*
}

#Proceso
echo "Actualizando estado del workitem . . . "
update ${COMMAND}

e=${?}
if [ $e -eq 0 ]; then
	echo "\e[32mGOOD\e[0m"
fi
if [ $e -eq 1 ]; then
	echo "\e[31mBAD\e[0m"
fi
