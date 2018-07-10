#! /bin/bash
#************************************************************************
#* PROGRAMA		: SH_SISACT_liberarLineasAnuladas.sh		*
#* AUTOR		: KEVYN ESTRADA CASTILLO			*
#* MODIFICADO		: -						*
#* FECHA MODIF.		: 23/02/2018					*
#* MOTIVO CAMBIO	: Version Inicial				*
#* VERSION		: 1.0						*
#* PARAMETROS IN	: -						*
#************************************************************************
#Inicializacion de variables de ruta
DIR=/home/fallas/SHELLS/operacionales/Workitem

. ${DIR}/bin/.varset
. ${DIR}/bin/.passet
. ${DIR}/bin/.functionset

YMD_HMS=`date +%Y%m%d_%H%M%S`

#Variables Rutas
DIRTEMP=${DIR}/temp
DIRLOG=${DIR}/log

FILETEMP=${DIRTEMP}/bodyMail_${YMD_HMS}.tmp
FILELOG=${DIRLOG}/createWorkitem_${YMD_HMS}.log

#Variables
USER_GC=E751006	#Usuario del Gestor de la Configuracion de RTC
USER_SF=C18263	#Usuario SOAP de Fallas de Claro
USER_AP=E700136	#Usuario Analista Programador

#Proceso

rem=$1
com=$2
soa=$3
if [ -z $rem ] || [ -z $com ] || [ -z $soa ]; then
	echo "Usage: cwi <remedy> <proyecto> <soap>"
	exit
fi

echo "Info: Esta version de script bash para la creacion de Workitem esta obsoleta, usa \e[1mcreateWorkitem2.sh\e[0m en su lugar."
exit

enviomail()
{
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
}
save()
{
	result=`wcl $1`
	if [ $? -eq 0 ]; then
		pmessage "Se creo con exito: $result|$2" ${FILELOG}
		echo "$2|$result">>${FILETEMP}
		return ${result}
	else
		pmessage "Ocurrio un error: $result|$2" ${FILELOG}
		echo "$2|$result" | sed ':a;N;$!ba;s/\n/<br>/g'>>${FILETEMP}
		enviomail
		exit
	fi
}
pheader "${rem}" "${com}" "${soa}" ${FILELOG}
pmessage "Creando workitems . . ." ${FILELOG}
pmessage "" ${FILELOG}
save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=com.ibm.team.workitem.workItemType.milestone Cod_Proyect_Obj=$rem id.proyecto.solicutd=NO internalPriority=Alta owner=$USER_SF Proyecto.Responsable=$USER_SF summary=$rem tipo.proyecto.solicitud=Requerimientos tipo_gerencia_objec=SOPORTE tipo_proveedores_object=EVERIS" "${rem}"
LASTID_01=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=com.ibm.team.workitem.workItemType.businessneed @link_parent=$LASTID_01 Aplicacion=$com category=CEQ.$rem.$com Cod_Proyec_Sol=$rem Coordinador_de_Desarrollo=$USER_AP description=$rem Falla.Responsable=$USER_SF id_urgencias00=NO internalPriority=Alta owner=$USER_SF summary=FALLA.$rem.$com target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/01.$rem.$com.DESARROLLO tipo.gerencia.sol=SOPORTE tipo.proveedores.sol=EVERIS type.solicitud=Requerimientos" "FALLA.${rem}.${com}"
LASTID_02=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=promover @link_parent=$LASTID_02 category=CEQ.$rem.$com internalPriority=Alta owner=$USER_GC summary=PRM.$rem.$com.DESARROLLO target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/01.$rem.$com.DESARROLLO" "PROM.${rem}.${com}.DESARROLLO"
LASTID_03=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=promover @link_parent=$LASTID_02 category=CEQ.$rem.$com internalPriority=Alta owner=$USER_GC summary=PRM.$rem.$com.CERTIFICACION target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/02.$rem.$com.CERTIFICACION" "PROM.${rem}.${com}.CERTIFICACION"
LASTID_04=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=promover @link_parent=$LASTID_02 category=CEQ.$rem.$com internalPriority=Alta owner=$USER_GC summary=PRM.$rem.$com.COMITE_PP target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/03.$rem.$com.COMITE_PP" "PROM.${rem}.${com}.COMITE_PP"
LASTID_05=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=promover @link_parent=$LASTID_02 category=CEQ.$rem.$com internalPriority=Alta owner=$USER_GC summary=PRM.$rem.$com.PRODUCCION target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/04.$rem.$com.PRODUCCION" "PROM.${rem}.${com}.PRODUCCION"
LASTID_06=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=authorization @link_parent=$LASTID_03 category=CEQ.$rem.$com cod_project_au=$rem owner=$USER_SF summary=AUT.$rem.$com.DESARROLLO target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/01.$rem.$com.DESARROLLO" "AUT.${rem}.${com}.DESARROLLO"
LASTID_07=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=authorization @link_parent=$LASTID_04 category=CEQ.$rem.$com cod_project_au=$rem owner=$USER_SF summary=AUT.$rem.$com.CERTIFICACION target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/02.$rem.$com.CERTIFICACION" "AUT.${rem}.${com}.CERTIFICACION"
LASTID_08=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=task @link_related=$LASTID_07 Acti_Cod_Project=$rem category=CEQ.$rem.$com Id_nombre_actividad=DES_FUENTES id_proceso_negocio_Act=SOPORTE internalPriority=Alta owner=$USER_AP summary=ACT.$rem.$com.DES_FUENTES target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/01.$rem.$com.DESARROLLO tipo_gerencia_act=SOPORTE tipo_proveedores=EVERIS" "ACT.${rem}.${com}.DES_FUENTES"
LASTID_09=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=task @link_related=$LASTID_06 Acti_Cod_Project=$rem category=CEQ.$rem.$com Id_nombre_actividad=PRD_INSTALACION id_proceso_negocio_Act=SOPORTE internalPriority=Alta owner=$soa summary=ACT.$rem.$com.PRD_INSTALACION target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/04.$rem.$com.PRODUCCION tipo_gerencia_act=SOPORTE tipo_proveedores=EVERIS" "ACT.${rem}.${com}.PRD_INSTALACION"
LASTID_10=$?

save "-create repository=$RTCURL user=$RTCUSER password=$RTCPASS projectArea=$RTCAREA workItemType=documentacion @link_related=$LASTID_07 category=CEQ.$rem.$com owner=$USER_AP summary=DOC.$rem.$com.DESARROLLO target=LT.FALLA.$rem.$com/R.FALLA.$rem.$com/01.$rem.$com.DESARROLLO" "DOC.${rem}.${com}.DESARROLLO"

enviomail

pmessage "" ${FILELOG}
pmessage "Proceso terminado." ${FILELOG}

exit
