#! /bin/bash
#************************************************************************
#* PROGRAMA		: reporteEaiBacklog.sh				*
#* AUTOR		: KEVYN ESTRADA CASTILLO			*
#* FECHA MODIF.		: 21/03/2018					*
#* MOTIVO CAMBIO	: Version Inicial				*
#* VERSION		: 1.0						*
#************************************************************************
DIR=/home/fallas/CURL
. ${DIR}/bin/.mailset
. ${DIR}/bin/.varset
. ${DIR}/bin/.passet

#Inicializacion de variables de ruta
DAYFORMAT=`date +%d/%m/%Y`
TODAY=`date +%Y%m%d_%H%M%S`

DIRTEMP=${DIR}/temp
DIRDATA=${DIR}/data
DIRLOG=${DIR}/log

FILETEMP=${DIRTEMP}/reporteEaiBacklog_${TODAY}.temp
FILEJSON=${DIRDATA}/reporteEaiBacklog_${TODAY}.json
FILEDATA=${DIRDATA}/reporteEaiBacklog_${TODAY}.dat
FILELOG=${DIRLOG}/reporteEaiBacklog_${TODAY}.log
# JIRA_QUERY="project%20in%20(EAI%2COSB%2COSB_MR%2CTIM-FTP1%2CPROCPP_MIG%2CJANUS%2CSGA%2CSIGPEL)%20AND%20Proveedor%3DEveris%20AND%20status%20in%20(Analisis%2CBacklog%2C%27En%20curso%27)%20AND%20%22Analista%20Programador%22%20is%20EMPTY"
JIRA_QUERY="project%20in%20(EAI%2COSB%2COSB_MR%2CTIM-FTP1%2CPROCPP_MIG%2CJANUS%2CSGA%2CSIGPEL)%20AND%20Proveedor%3DEveris%20AND%20status%20in%20(Analisis%2CBacklog%2C%27En%20curso%27)"
JIRA_SESSION_ID=`curl -s -H "Content-Type: application/json" -d "{\"username\":\"${JIRA_LOGIN}\",\"password\":\"${JIRA_PASSWORD}\"}" -X POST ${JIRA_URL}${JIRA_AUTH_URI} | sed -r 's/^.+JSESSIONID","value":"([^"]+).+$/\1/ig'`
echo "Obteniendo data . . ." >> ${FILELOG}
curl -s -H "Content-Type: application/json" -b JSESSIONID=${JIRA_SESSION_ID} ${JIRA_URL}${JIRA_API_SEARCH}?jql=${JIRA_QUERY} -o $FILEJSON
cat "$FILEJSON" | jq --raw-output '.issues[] | 
.key
 + "|" + 
.fields .summary
 + "|" + 
.fields .project .name
 + "|" + 
.fields .priority .name
 + "|" + 
.fields .status .name
 + "|" + 
.fields .customfield_10007 .value 
 + "|" + 
.fields .created
 + "|" + 
.fields .customfield_10114 .child .value
' >> ${FILETEMP}
while read p; do
	codigo=`echo $p | awk -F'|' '{ print $1 }'`
	remedy=`echo $p | awk -F'|' '{ print $2 }'`
	proyecto=`echo $p | awk -F'|' '{ print $3 }'`
	prioridad=`echo $p | awk -F'|' '{ print $4 }'`
	estado=`echo $p | awk -F'|' '{ print $5 }'`
	proveedor=`echo $p | awk -F'|' '{ print $6 }'`
	fecha=`echo $p | awk -F'|' '{ print $7 }'`
	fecha=`date +%d/%m/%Y -d "$fecha"`
	assigned=`echo $p | awk -F'|' '{ print $8 }'`
	echo "<tr>">>${FILEDATA}
	echo "<td><a href=\"$JIRA_URL/browse/$codigo\">$remedy</a></td>">>${FILEDATA}
	echo "<td>$proyecto</td>">>${FILEDATA}
	echo "<td>$prioridad</td>">>${FILEDATA}
	echo "<td>$estado</td>">>${FILEDATA}
	echo "<td>$proveedor</td>">>${FILEDATA}
	echo "<td>$fecha</td>">>${FILEDATA}
	echo "<td>$assigned</td>">>${FILEDATA}
	echo "</tr>">>${FILEDATA}
done <${FILETEMP}
if [ -s ${FILETEMP} ]; then
echo "Envio de correo" >> ${FILELOG}
mail -a "MIME-Version: 1.0" -a "Content-Type: text/html" -s "${MAIL_SUBJECT}" "${MAIL_TO}" -c "${MAIL_CC}" <<EOF
<html><head><style>table {border-collapse: collapse}table td, th {border: 1px solid black;padding: 4px 8px;text-align: center}</style></head><body><p>Sres.</p>
<p>Se envia consolidado de las siguientes fallas en analisis y backlog del dia $DAYFORMAT.</p>
<table>
<tr>
<th>Resumen</th>
<th>Proyecto</th>
<th>Prioridad</th>
<th>Estado</th>
<th>Proveedor</th>
<th>Creada</th>
<th>Asignado a</th>
</tr>`cat $FILEDATA`</table>
<p>Saludos.</p></body></html>
EOF
fi
echo "Depuracion de archivos" >> ${FILELOG}
rm -rf ${FILEJSON}
rm -rf ${FILETEMP}
rm -rf ${FILEDATA}
