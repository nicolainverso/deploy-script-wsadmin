#/bin/sh
#  ███████ ███    ███  █████  ██████  ████████     ██████  ███████ ██████  ██       ██████  ██    ██ 
#  ██      ████  ████ ██   ██ ██   ██    ██        ██   ██ ██      ██   ██ ██      ██    ██  ██  ██  
#  ███████ ██ ████ ██ ███████ ██████     ██        ██   ██ █████   ██████  ██      ██    ██   ████   
#       ██ ██  ██  ██ ██   ██ ██   ██    ██        ██   ██ ██      ██      ██      ██    ██    ██    
#  ███████ ██      ██ ██   ██ ██   ██    ██        ██████  ███████ ██      ███████  ██████     ██    
#                                                                                                    
#  v1.1
#  @author Nicola Inverso    
#  @date 22/02/2021

#colori per log
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

properties_file="deploy.properties"

#variabili globali lette da properties
WS_ADMIN_PATH=''
BASE_PATH_SCRIPT=''
WS_ADMIN_USR=''
WS_ADMIN_PASS=''
LOGS_FOLDER=''
HOSTNAME=''
PROFILE_ROOT=''

DEPLOY_LOGPATH=''   #logfolder + filename
DEBUG_LOG='debug.txt'

main()
{
	print_logo
	load_properties
	
	DEPLOY_LOGPATH=${DEPLOY_LOGPATH}'/'${HOSTNAME}$(date '+%Y-%m-%d')'.txt'
	
	#controllo se il parametro passato è una directory o un file
	if [[ -d $1 ]]; then
		logger "INFO" "$1 is a directory" "true" "false"
		read_ear_to_deploy $1
	elif [[ -f $1 ]]; then
		logger "INFO" "$1 is a single file" "true" "false"
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset}$1 is a single file" |& tee -a  "log.txt"
		install_single $1
	else
		logger "ERROR" "file to install not found!" "true" "false"
		exit 1
	fi
}

#lettura del file di propeties 
#in bash3 non esiste l'array associativo
load_properties()
{
	if [ -f "$properties_file" ]
	then
		logger "INFO" "Reading properties from $properties_file" "true" "false"
		
		while IFS=$':= \t' read key value; do
			if [[ $key != \#* ]] && [[ $key != '' ]]
			then		  
				if [ "$key" = "WS_ADMIN_PATH" ]; then
					WS_ADMIN_PATH=$value
					logger "INFO" "Load WS_ADMIN_PATH=$value" "true" "false"
				fi
				if [ "$key" = "BASE_PATH_SCRIPT" ]; then
					BASE_PATH_SCRIPT=$value
					logger "INFO" "Load BASE_PATH_SCRIPT=$value" "true" "false"
				fi
				if [ "$key" = "WS_ADMIN_USR" ]; then
					WS_ADMIN_USR=$value
					logger "INFO" "Load WS_ADMIN_USR=$value" "true" "false"
				fi
				if [ "$key" = "WS_ADMIN_PASS" ]; then
					WS_ADMIN_PASS=$value
					logger "INFO" "Load WS_ADMIN_PASS=*******" "true" "false"
				fi
				if [ "$key" = "DEPLOY_LOGPATH" ]; then
					DEPLOY_LOGPATH=$value
					logger "INFO" "Load DEPLOY_LOGPATH=$value" "true" "false"
				fi
				if [ "$key" = "HOSTNAME" ]; then
					HOSTNAME=$value
					logger "INFO" "Load HOSTNAME=$value" "true" "false"
				fi
				if [ "$key" = "PROFILE_ROOT" ]; then
					PROFILE_ROOT=$value
					logger "INFO" "Load PROFILE_ROOT=$value" "true" "false"
				fi
			fi
		done < $properties_file
	else
	  echo "$(date '+%Y-%m-%d %H:%M:%S') ${red}[ERROR]${reset} $properties_file not found." |& tee -a  "log.txt"
	fi
}

#se viene indicata una directory vengono listati tutti gli ear presenti
#e chiesto se si vogliono installare
read_ear_to_deploy()
{
	echo ""
	logger "INFO" "Ear presenti:" "true" "false"
	
	for file in $1/*.ear; do
		logger "INFO" "${file##*/}" "true" "false"
	done
	printf "\n"
	read -p "Sei sicuro di proseguire?[y/n]" -n 1 -r
	printf "\n\n"
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		install_from_directory $1
	fi
}

#la funzione installa tutti i file presenti nella directori passata come parametro
install_from_directory()
{
    for file in $1/*.ear; do
		logger "INFO" "Try to install ${file##*/}" "true" "true"
		install_single $file
	done
	
}

#la funzione installa il singolo ear, il path viene passato come parametro ${1}
install_single()
{
	file_path=${1} 			 #path del file completo
	fullfile=${1##*/}		 #nome file con estenzione
	filename=${fullfile%%.*} #nome file senza estenzione
	config_name=""
	script_finded=""
	ws_admin_pass=""
	java_option=''
	#java_option="-javaoption -Dpython.path=<profile_root/profile_name>:<profile_root>"
	#se settato il profile root inserisco la javaOption per caricare gli script libreria
	if [[ ${#PROFILE_ROOT} -gt 0 ]]; then
		java_option=' -Dpython.path='${BASE_PATH_SCRIPT}'/earupdate.py'
		echo $java_option
	fi
	
	#se la password wsadmin esiste la inserisco nel lancio del comando di update
	if [[ ${#WS_ADMIN_PASS} -gt 0 ]]; then
		ws_admin_pass="-password ${WS_ADMIN_PASS}"
	fi
	
	logger "INFO" "Searching for Jython script for $fullfile" "true" "false"
	
	#ricerca dello script di deploy per l'ear ricevuto
	for conf in $BASE_PATH_SCRIPT/*; do
	
		config_file_name=${conf##*/}			   #nomefile jython file.py
		config_name=${config_file_name%%.*} 	   #nomefile senza estenzione
		
		if [[ $filename =~ $config_name ]]; then   #se il nome file.ear contiene il nome file .py lo script esiste
		   script_finded=$conf					   #salvo tutto il nome script
		   logger "INFO" "configurazione trovata al path $script_finded" "true" "true"
		   break
		fi
	done
	
	#controllo se viene trovato lo script python
	if [[ ${#script_finded} -gt 0 ]]; then
		logger "INFO" "Try to install ${file_path} with script ${script_finded}" "true" "true"
		logger "INFO" "Lancio di wsadmin" "true" "true"
		CMD=${WS_ADMIN_PATH}' -user '${WS_ADMIN_USR}' '${ws_admin_pass}' -f /ear/smart-deploy/config/earupdate.py -f '${script_finded}' '${file_path}' '${DEPLOY_LOGPATH}' '${BASE_PATH_SCRIPT}'/ -lang jython' 
		logger "INFO" $CMD "true" "true"
		
		eval $CMD #lancio del comando
		
		logger "INFO" "End wsadmin execution for $fullfile" "true" "true"
		printf "\n\n"

	else
	   logger "ERROR" "Jython script for deploy not found" "true" "true"
       read -p "Sei sicuro di proseguire?[y/n]" -n 1 -r
	   printf "\n\n"
	   if [[ $REPLY =~ ^[Yy]$ ]]
	   then
			echo "ok"
	   fi
	fi
}

logger()
{
	log_type=$1
	message=$2
	write_on_debug_log=$3
	write_on_deploy_log=$4
	
    date_string=$(date '+%H:%M:%S')
    log_level=""
    if [ "$log_type" = "INFO" ]; then
		log_level="${green}[INFO]${reset}"
    fi
    if [ "$log_type" = "ERROR" ]; then
		log_level="${red}[ERROR]${reset}"
    fi
	if [ "$write_on_debug_log" = "true" ]; then
		echo $date_string'|'$HOSTNAME'|' $message >> $DEBUG_LOG
    fi
	if [ "$write_on_deploy_log" = "true" ]; then
		echo $date_string'|'$HOSTNAME'|'$log_type'|' $message >> $DEPLOY_LOGPATH
    fi
	echo $log_level' '$message
}

print_logo()
{
	printf "\n
███████╗███╗   ███╗ █████╗ ██████╗ ████████╗ ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗
██╔════╝████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝ ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝
███████╗██╔████╔██║███████║██████╔╝   ██║    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ 
╚════██║██║╚██╔╝██║██╔══██║██╔══██╗   ██║    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  
███████║██║ ╚═╝ ██║██║  ██║██║  ██║   ██║    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   
╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝  
v1.1
\n"
}



main $1