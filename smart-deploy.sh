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

DEPLOY_LOGPATH=''   #logfolder + filename
DEBUG_LOG='debug.txt'

main()
{
	print_logo
	load_properties
	
	DEPLOY_LOGPATH=${DEPLOY_LOGPATH}'/'${HOSTNAME}$(date '+%Y-%m-%d')'.txt'
	start_log='Smart deploy lanciato da'
	echo ${start_log}
	log "$start_log"
	
	#controllo se il parametro passato è una directory o un file
	if [[ -d $1 ]]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} $1 is a directory" |& tee -a  "log.txt"
		read_ear_to_deploy $1
	elif [[ -f $1 ]]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset}$1 is a single file" |& tee -a  "log.txt"
		install_single $1
	else
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${red}[ERROR]${reset} file to install not found!" |& tee -a  "log.txt"
		exit 1
	fi
}

#lettura del file di propeties 
#in bash3 non esiste l'array associativo
load_properties()
{
	if [ -f "$properties_file" ]
	then
	    echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO] ${reset}Reading properties from $properties_file"	|& tee -a  "log.txt"	
		while IFS=$':= \t' read key value; do
			if [[ $key != \#* ]] && [[ $key != '' ]]
			then		  
				if [ "$key" = "WS_ADMIN_PATH" ]; then
					WS_ADMIN_PATH=$value
					logger "INFO" "Load WS_ADMIN_PATH=$value" "true" "false"
					#echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load WS_ADMIN_PATH=$value" |& tee -a  "log.txt"
				fi
				if [ "$key" = "BASE_PATH_SCRIPT" ]; then
					BASE_PATH_SCRIPT=$value
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load BASE_PATH_SCRIPT=$value" |& tee -a  "log.txt"
				fi
				if [ "$key" = "WS_ADMIN_USR" ]; then
					WS_ADMIN_USR=$value
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load WS_ADMIN_USR=$value" |& tee -a  "log.txt"
				fi
				if [ "$key" = "WS_ADMIN_PASS" ]; then
					WS_ADMIN_PASS=$value
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load WS_ADMIN_PASS=*******" |& tee -a  "log.txt"
				fi
				if [ "$key" = "DEPLOY_LOGPATH" ]; then
					DEPLOY_LOGPATH=$value
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load DEPLOY_LOGPATH=$value" |& tee -a  "log.txt"
				fi
				if [ "$key" = "HOSTNAME" ]; then
					HOSTNAME=$value
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Load HOSTNAME=$value" |& tee -a  "log.txt"
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
	printf "\n$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Ear presenti:${reset}\n\n" |& tee -a  "log.txt"
	
	for file in $1/*.ear; do
		echo "${file##*/}" |& tee -a  "log.txt"
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
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Try to install ${file##*/}" |& tee -a  "log.txt"
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
	#java_option="-javaoption -Dpython.path=<profile_root/profile_name>:<profile_root>"
	
	#se la password wsadmin esiste la inserisco nel lancio del comando di update
	if [[ ${#WS_ADMIN_PASS} -gt 0 ]]; then
		ws_admin_pass="-password ${WS_ADMIN_PASS}"
	fi
	
	echo "${green}[INFO]${reset} Searching for Jython script for $fullfile" |& tee -a  "log.txt"
	
	#ricerca dello script di deploy per l'ear ricevuto
	for conf in $BASE_PATH_SCRIPT/*; do
	
		config_file_name=${conf##*/}			   #nomefile jython file.py
		config_name=${config_file_name%%.*} 	   #nomefile senza estenzione
		
		if [[ $filename =~ $config_name ]]; then   #se il nome file.ear contiene il nome file .py lo script esiste
		   script_finded=$conf					   #salvo tutto il nome script
		   echo "${green}[INFO]${reset} configurazione trovata al path $script_finded" |& tee -a  "log.txt"
		   break
		fi
	done
	
	#controllo se viene trovato lo script python
	if [[ ${#script_finded} -gt 0 ]]; then
		log "Try to install ${file_path} with script ${script_finded}"
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Esecuzione del deploy di $script_finded" |& tee -a  "log.txt" 
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} Lancio di wsadmin" |& tee -a  "log.txt"
		CMD=${WS_ADMIN_PATH}' -user '${WS_ADMIN_USR}' '${ws_admin_pass}' -f '${script_finded}' '${file_path}' '${DEPLOY_LOGPATH}' -lang jython' 
		echo $CMD
		eval $CMD #lancio del comando
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${green}[INFO]${reset} End wsadmin execution for $fullfile " |& tee -a  "log.txt"
		printf "\n\n"

	else
	   echo "$$(date '+%Y-%m-%d %H:%M:%S') {red}[ERROR] ${reset} Jython script for deploy not found" |& tee -a  "log.txt"
       read -p "Sei sicuro di proseguire?[y/n]" -n 1 -r
	   printf "\n\n"
	   if [[ $REPLY =~ ^[Yy]$ ]]
	   then
			echo "ok"
	   fi
	fi
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
		echo $date_string'|'$HOSTNAME'|'$log_level'|' $message >> $DEPLOY_LOGPATH
    fi
	echo $log_level' '$message 'NEW LOGGER'
}
log()
{
	echo $(date '+%H:%M:%S')'|'$HOSTNAME'|' $1 >> $DEPLOY_LOGPATH
}

main $1