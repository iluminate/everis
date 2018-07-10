USERNAME=E700911
PASSWORD=May2018+
HOSTNAME=https://172.19.112.112:9443

AREAPROJECT=([02.GESTION.FALLAS.3]="_-QCWgD1CEeaUR4VCDBFC8w" [02.GESTION.FALLAS.1]="_wdOgcEmFEeiQd")

RUTA=/home/fallas/SHELLS/operacionales/Timeline

TODAY=`date +%Y%m%d_%H%M%S`

DIRTEMP=${RUTA}/temp
DIRLOG=${RUTA}/log

FILECOOKIE=${DIRTEMP}/cookie_${TODAY}.temp
FILEDATA01=${DIRTEMP}/projectDevelopmentLines_${TODAY}.temp
FILEDATA02=${DIRTEMP}/iterations_${TODAY}.temp
FILELOG=${DIRLOG}/obtenerTimeline_${TODAY}.log

pheader () {
	clear
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) ******************************************************"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Iniciando proceso obtener linea de tiempo"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Fecha/Hora (Inicio)"'\t'": `date +'%d/%m/%Y %H:%M:%S'`"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Nro. Proceso"'\t''\t'": $$"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Usuario"'\t''\t''\t'": `whoami`"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Cliente"'\t''\t''\t'": `echo $SSH_CONNECTION | awk '{print $1}'`"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) ******************************************************"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`)"
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) ******************************************************" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Iniciando proceso obtener linea de tiempo" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Fecha/Hora (Inicio)"'\t'": `date +%d/%m/%Y' '%H:%M:%S`" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Nro. Proceso"'\t''\t'": $$" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Usuario"'\t''\t''\t'": `whoami`" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) Cliente"'\t''\t''\t'": `echo $SSH_CONNECTION | awk '{print $1}'`" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`) ******************************************************" >> ${1}
	echo "(`date +%d/%m/%Y' '%H:%M:%S`)" >> ${1}
}

pmessage ()
{
	echo "(`date +'%d/%m/%Y %H:%M:%S'`) $1"
	echo "(`date +'%d/%m/%Y %H:%M:%S'`) $1" >> $2
}

if [ -z $1 ]; then
	echo "Usar:"
	echo "	obtenerTimeline.sh <Remedy>.<Componente>"
	exit
fi

pheader ${FILELOG}

curl -s -c ${FILECOOKIE} ${HOSTNAME}/ccm/authenticated/j_security_check --data-urlencode j_username=${USERNAME} --data-urlencode j_password=${PASSWORD} --insecure

curl -s -b ${FILECOOKIE} "${HOSTNAME}/ccm/service/com.ibm.team.process.internal.service.web.IProcessWebUIService/projectDevelopmentLines?uuid=${AREAPROJECT}&includeArchived=true&processAreaContext=1" --insecure >> ${FILEDATA01}

pmessage "Obteniendo valor de ITEMID" ${FILELOG}

ITEMID=`cat ${FILEDATA01} | grep -B4 $1 | sed -n 's/<itemId>\(.*\)<\/itemId>/\1/p' | awk '{$1=$1};1'`

i=0
while [ ${i} -lt ${#AREAPROJECT[@]} ]
do
	if [ -z $ITEMID ]; then
		pmessage "No se pudo encontrar el itemId en el area de proyecto 02.GESTION.FALLAS.1" ${FILELOG}
		rm -f ${FILECOOKIE}
		rm -f ${FILEDATA01}
		exit
	fi
	i=`expr $a + 1`
done

pmessage "ITEMID: ${ITEMID}" ${FILELOG}

curl -s -b ${FILECOOKIE} ${HOSTNAME}/ccm/service/com.ibm.team.process.internal.service.web.IProcessWebUIService/iterations?uuid=${ITEMID} --insecure >> ${FILEDATA02}

ITERATION=`cat ${FILEDATA02} | grep -B14 \/iterations | grep -B7 current | sed -n 's/<label>\(.*\)<\/label>/\1/p' | awk '{$1=$1};1'`

pmessage "Resultado: \e[32m${ITERATION}\e[0m" ${FILELOG}

pmessage "" ${FILELOG}
pmessage "******************************************************" ${FILELOG}
pmessage "Fin del proceso obtener lineas de tiempo." ${FILELOG}
pmessage "******************************************************" ${FILELOG}

rm -f ${FILECOOKIE}
rm -f ${FILEDATA01}
rm -f ${FILEDATA02}
