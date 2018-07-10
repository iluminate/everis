#! /bin/bash
#************************************************************************
#* PROGRAMA		: SH_SISACT_liberarLineasAnuladas2.sh		*
#* AUTOR		: KEVYN ESTRADA CASTILLO			*
#* MODIFICADO		: -						*
#* FECHA MODIF.		: 25/05/2018					*
#* MOTIVO CAMBIO	: Version Inicial				*
#* VERSION		: 2.0						*
#* PARAMETROS IN	: Remedy, Project, Soap				*
#************************************************************************
#Inicializacion de variables de ruta
DIR=/home/fallas/SHELLS/operacionales/Workitem

. ${DIR}/bin/.varset
. ${DIR}/bin/.passet
. ${DIR}/bin/.functionset

YMD_HMS=`date '+%Y%m%d_%H%M%S'`
ini=`date '+%s'`

#Variables Rutas
DIRTEMP=${DIR}/temp
DIRLOG=${DIR}/log
DIROUTPUT=${DIR}/output
DIRINPUT=${DIR}/input
DIRBIN=${DIR}/bin

FILETEMP=${DIRTEMP}/bodyMail_${YMD_HMS}.tmp
FILELOG=${DIRLOG}/createWorkitem_${YMD_HMS}.log
FILEOUTPUT=${DIROUTPUT}/createWorkitem_${YMD_HMS}.out
PLANTILLA=${DIRBIN}/.template
FILEINPUT=${DIRINPUT}/createWorkitem_${YMD_HMS}.json


#Proceso
rem=$1
com=$2
soa=$3
if [ -z $rem ] || [ -z $com ] || [ -z $soa ]; then
   echo "Usage: cwi <remedy> <proyecto> <soap>"
   exit
fi

pheader "${rem}" "${com}" "${soa}" ${FILELOG}
pmessage "Creando workitems . . ." ${FILELOG}
pmessage "" ${FILELOG}

export rem com soa
REQUEST=`envsubst < ${PLANTILLA}`
echo "${REQUEST}" >> ${FILELOG}
echo "${REQUEST}" >> ${FILEINPUT}

curl --silent -X POST ${WS_CREATEWI} -H "Content-Type: application/json" -d @${FILEINPUT} >> ${FILEOUTPUT}
if [ 0 -ne $? ] || [ ! -s ${FILEOUTPUT} ]; then
   pmessage "Error: El servicio ${WS_CREATEWI} no respondio correctamente" ${FILETEMP}
   pmessage "" ${FILELOG}
   fin=`date '+%s'`
   total=`expr $fin - $ini`
   pmessage "Ejecucion terminada en ${total} segundos" ${FILELOG}
   exit
fi

CODERROR=`cat ${FILEOUTPUT} | jq -r '.codigoError'`
MSGERROR=`cat ${FILEOUTPUT} | jq -r '.mensajeError'`

if [ ${CODERROR} -eq 0 ]; then
	cat ${FILEOUTPUT} | jq -r '.listaWorkitem []' > ${FILETEMP}
else
	if [ ${CLISTAWI} -gt 0 ]; then
		cat ${FILEOUTPUT} | jq -r '.listaWorkitem []' > ${FILETEMP}
	fi
	cat ${FILEOUTPUT} | jq -r '"|" + .mensajeError' >> ${FILETEMP}
fi

cat ${FILEOUTPUT} | jq
cat ${FILEOUTPUT} | jq '' >> ${FILELOG}

pmessage "${MSGERROR}" ${FILELOG}

mail -a "Content-Type: text/html" -s "[${rem}] - ${com} : Creacion de Workitems" "${from}" <<EOF
<html>
   <head>
      <style>
         body {font-family: Arial, Helvetica, sans-serif;font-size: 12px;}
         table {border-collapse: collapse;}
         table, td, th {border: 1px solid black;padding: 4px 8px;text-align: center;}
         td {text-align: left;}
      </style>
   </head>
   <body>
      <p>Sres.</p>
      <p>Se envia proceso de creacion de Workitem</p>
      <table>
         <tr>
            <th>Codigo</th>
            <th>Resumen</th>
         </tr>
         `awk -F'|' '{print "<tr>";for(i=1;i<=NF;i++)print "<td>"$i"</td>";print "</tr>"}' $FILETEMP`
      </table>
      <p>Saludos.</p>
   </body>
</html>
EOF
rm -rf ${FILETEMP}
pmessage "" ${FILELOG}

fin=`date '+%s'`
total=`expr $fin - $ini`

pmessage "Ejecucion terminada en ${total} segundos" ${FILELOG}
exit
