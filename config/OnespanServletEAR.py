import sys
import time
import earupdate

#-------------------------------
# Global definition
#-------------------------------

earPath=sys.argv[0]                  #path ear da installare
logFileName=sys.argv[1]              #nome file dove loggare 
scriptName="OnespanServletEAR.py"    #nome script eseguito
applicationName='OnespanServletEAR'  #nome applicazione
timeToWaitStartup=5                  #tempo di attesa per verificare lo startup (secondi)
maxRetry=5                           #massimo numero di tentativi di osservazione dello startup        

earupdate.run(earPath,logFileName,scriptName,applicationName,timeToWaitStartup,maxRetry)


