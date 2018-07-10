#! /bin/bash
#************************************************************************
#* PROGRAMA		: reporteEaiBacklog.sh				*
#* AUTOR		: KEVYN ESTRADA CASTILLO			*
#* FECHA MODIF.		: 05/07/2018					*
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

FILETEMP=${DIRTEMP}/reporteFaltaControlHoras_${TODAY}.temp
FILEJSON=${DIRDATA}/reporteFaltaControlHoras_${TODAY}.json
FILEDATA=${DIRDATA}/reporteFaltaControlHoras_${TODAY}.dat
FILEHTML=${DIRDATA}/reporteFaltaControlHoras_${TODAY}.mail
FILELOG=${DIRLOG}/reporteFaltaControlHoras_${TODAY}.log

JIRA_QUERY="%22Analista%20Programador%22%20in%20(%22Miguel%20Vegas%20Santana%22%2C%22Gerardo%20Gonzalo%20Aldave%22%2C%22Carlos%20Paz%20Urcia%22)%20AND%20status%20not%20in%20(Devuelto%2CFinalizado)%20and%20updatedDate%20%3E%20startOfWeek()%20"

JIRA_SESSION_ID=`curl -s -H "Content-Type: application/json" -d "{\"username\":\"${JIRA_LOGIN}\",\"password\":\"${JIRA_PASSWORD}\"}" -X POST ${JIRA_URL}${JIRA_AUTH_URI} | sed -r 's/^.+JSESSIONID","value":"([^"]+).+$/\1/ig'`
curl -s -H "Content-Type: application/json" -b JSESSIONID=${JIRA_SESSION_ID} ${JIRA_URL}${JIRA_API_SEARCH}?jql=${JIRA_QUERY} -o $FILEJSON

cat $FILEJSON | jq --raw-output '.issues[] | .key + "|" + .id + "|" + .self' > $FILETEMP

while read p; do
	key=`echo $p | awk -F'|' '{ print $1 }'`
	code=`echo $p | awk -F'|' '{ print $2 }'`
	self=`echo $p | awk -F'|' '{ print $3 }'`
	TEMPPERID=$DIRTEMP/temp_perid_$code_`date +%Y%m%d_%H%M%S`.temp
	curl -s -H "Content-Type: application/json" -b JSESSIONID=${JIRA_SESSION_ID} $self -o $TEMPPERID
	TEMPHEAD=`cat $TEMPPERID | jq --raw-output '.fields | .summary + "|" + .customfield_10114 .child .value'`
	TEMPBODY=$DIRTEMP/temp_body_$code_`date +%Y%m%d_%H%M%S`.temp
	cat $TEMPPERID | jq '.fields .worklog .worklogs[] | 
	.updated + "|" +	
	(.timeSpentSeconds|tostring)' >> $TEMPBODY
	rm -rf ${TEMPPERID}
	sumasegundos=0
	while read o; do
		data=`echo $o | sed 's/^.\|.$//g'`
		fecha=`echo $data | awk -F'|' '{ print $1 }'`
		segundos=`echo $data | awk -F'|' '{ print $2 }'`
		fecha=`echo $fecha | grep -oP '[\d]+-[\d]+-[\d]+'`
		hoy=`date '+%Y-%m-%d'`
		ayer=`date --date='1 day ago' '+%Y-%m-%d'`
		if [ "$fecha" = "$hoy" ]; then
			sumasegundos=`expr $segundos + $sumasegundos`
		fi
	done <${TEMPBODY}
	rm -f ${TEMPBODY}
	echo "$key|$TEMPHEAD|$sumasegundos" >> $FILEDATA
done <${FILETEMP}
rm -f ${FILEJSON}
rm -f ${FILETEMP}

temp_datetody=`date +%Y%m%d_%H%M%S`

# cat $FILEDATA

# awk -F"|" '{col[$3]=NR} END {for (i in col) print i, col[i]}' $FILEDATA | sort
USERTEMP=$DIRTEMP/Users_`date +%Y%m%d_%H%M%S`.temp

echo "`awk -F"|" '{col[$3]++} END {for (i in col) print i, col[$1]}' $FILEDATA | sort`" >> $USERTEMP

# exit
while read j; do
	codigo=`echo $j | awk -F'|' '{ print $1 }'`
	remedy=`echo $p | awk -F'|' '{ print $2 }'`
	assigned=`echo $j | awk -F'|' '{ print $3 }'`
	link="<a href=\"$JIRA_URL/browse/$codigo\">$remedy</a>"
	goal=`echo $j | awk -F'|' '{ print $4 }'`
	goal=`expr $goal / 3600`
	fileassigned=`echo $assigned | sed 's/ //g'`_$temp_datetody.temp
	echo "$link|$goal" >> ${fileassigned}
done<${FILEDATA}

while read p; do

	user=`echo $p | awk -F'|' '{ print $1 }'`
	
	# echo "$user"

	# codigo=`echo $p | awk -F'|' '{ print $1 }'`
	# remedy=`echo $p | awk -F'|' '{ print $2 }'`
	# assigned=`echo $p | awk -F'|' '{ print $3 }'`
	# goal=`echo $p | awk -F'|' '{ print $4 }'`

	# cat `$user | sed 's/ //g'`_$temp_datetody.temp | awk -F'|' '{ print $1 }' | awk '{ $1<br> } END { print SUM }'
	link=`cat `echo $user | sed 's/ //g'`_$temp_datetody.temp | awk -F'|' '{ print $1 }' | tr -s '\n' ' '
	goal=`cat `echo $user | sed 's/ //g'`_$temp_datetody.temp | awk -F'|' '{ print $2 }' | awk '{ SUM += $1} END { print SUM }'`


	goal=`expr $goal / 3600`
	goal=`expr 9 - $goal`
	

	# unset x y sum; while IFS=, read x y; do ((sum[$x]+=y)); done <  input.csv; for i in ${!sum[@]}; do echo $i,${sum[$i]}; done
	
	
	echo "<tr>">>${FILEHTML}
	echo "<td>$user</td>">>${FILEHTML}
	# echo "<td><a href=\"$JIRA_URL/browse/$codigo\">$remedy</a></td>">>${FILEHTML}
	echo "$link">>${FILEHTML}
	echo "<td>$goal</td>">>${FILEHTML}
	echo "</tr>">>${FILEHTML}
done <${USERTEMP}

cat $FILEHTML
exit

rm -rf ${FILEDATA}
if [ -s ${FILEHTML} ]; then
mail -a "MIME-Version: 1.0" -a "Content-Type: text/html" -s "Regularizar Horas" "kestrada@everis.com" <<EOF
<html><head><style>table {border-collapse: collapse}table td, th {border: 1px solid black;padding: 4px 8px;text-align: center}</style></head><body><p>Sres.</p>
<p>regularizar sus horas pendientes del dia $DAYFORMAT</p>
<table>
<tr>
<th>Programador</th>
<th>Fallas</th>
<th>Horas pendientes</th>
</tr>
`cat $FILEHTML`
</table>
<p>Saludos.</p></body></html>
EOF
fi
rm -f ${FILEHTML}