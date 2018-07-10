BASEPATH=/home/fallas/SHELLS/cworkitem

#Carga de Variables de configuracion

DIR=/home/fallas/SHELLS/cworkitem

. ${DIR}/bin/.varset
. ${DIR}/bin/.functionset

#Variables

TODAY=`date +%Y%m%d_%H%M%S`

DIRLOG=${DIR}/log
FILELOG=${DIRLOG}/auchangeStatusAcept_${TODAY}.log

COMMAND1="-update repository=$RTCURL user=$RTCUSER password=$RTCPASS id=$1 com.ibm.team.workitem.workItemType.authorization.autho.jp=authorization.literal.l2"
COMMAND2="-update repository=$RTCURL user=$RTCUSER password=$RTCPASS id=$1 internalState=com.ibm.team.workitem.authorizationWorkflow.state.s2"
COMMAND3="-update repository=$RTCURL user=$RTCUSER password=$RTCPASS id=$1 internalState=com.ibm.team.workitem.authorizationWorkflow.state.s3"

#Proceso
pmessage "Ejecutando . . ." ${FILELOG}
r1=`wcl ${COMMAND1}`
if [ $? -eq 0 ]; then
	pmessage "Se cambio el campo Coordinador de Fallas: SI" ${FILELOG}
fi
r2=`wcl ${COMMAND2}`
if [ $? -eq 0 ]; then
	pmessage "Se cambio el estado del workitem: autorizacion" ${FILELOG}
fi
r3=`wcl ${COMMAND3}`
if [ $? -eq 0 ]; then
	pmessage "Se cambio el estado del workitem: aceptado" ${FILELOG}
fi

pmessage "Termino." ${FILELOG}
