#! /bin/bash
#************************************************************************
#* PROGRAMA		: cargaContribuidores.sh			*
#* AUTOR		: KEVYN ESTRADA CASTILLO			*
#* MODIFICADO		: -						*
#* FECHA MODIF.		: 07/05/2018					*
#* MOTIVO CAMBIO	: Version Inicial				*
#* VERSION		: 1.0						*
#* PARAMETROS IN	: -						*
#************************************************************************
#Inicializacion de variables de ruta
DIR=/home/fallas/SHELLS/operacionales/Contributor

DIRLOG=${DIR}/log
DIRDATA=${DIR}/data

YMD_HMS=`date +%Y%m%d_%H%M%S`

FILELOG=${DIRLOG}/Contributor_${YMD_HMS}.log
FILEDATA=${DIRDATA}/locations_${YMD_HMS}.csv

echo>${FILEDATA}
curl --header "Content-type: application/json" --request POST --data '{"auditoria": {"repository":"https://172.19.112.112:9443/ccm/","username":"E700911","password":"Jun2018+"},"name":""}' http://192.168.100.169:7012/ContributorWS/rest/contributor/search | jq -r '.[] | .codigo + "," + .nombre' >> ${FILEDATA}
countdb=`mongo fallas -quiet --eval "printjson(db.listacontribuidor.count())"`
countws=`cat ${FILEDATA} | sed '/^\s*#/d;/^\s*$/d' | wc -l | awk '{print $1}'`
if [ "$countdb" -lt "$countws" ]; then
	mongo fallas --eval "printjson(db.listacontribuidor.remove({}))"
	mongoimport -d fallas -c listacontribuidor --type csv --file ${FILEDATA} --fields codigo,nombre
	echo "Se realizo la Carga: $countws" >> ${FILELOG}
else
	echo "No se realizo la Carga" >> ${FILELOG}
fi
rm -f ${FILEDATA}
