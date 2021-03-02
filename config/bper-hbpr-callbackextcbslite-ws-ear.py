import sys
import time

#-------------------------------
# Global definition
#-------------------------------

earPath=sys.argv[0]                  #path ear da installare
logFileName=sys.argv[1]              #nome file dove loggare 
scriptName="OnespanServletEAR.py"    #nome script eseguito
applicationName='OnespanServletEAR'  #nome applicazione
timeToWaitStartup=5                  #tempo di attesa per verificare lo startup (secondi)
maxRetry=5                           #massimo numero di tentativi di osservazione dello startup        

   
def waitAppStart(appName):
    count = 0    
    while AdminApp.isAppReady(appName) and count < maxRetry:
       count = count + 1
       writeLog("INFO","Check:" + count)
       time.sleep(timeToWaitStartup)
       
    if count==(maxRetry-1):
       writeLog("ERROR","Startup failed")

def writeLog(logType,message):
    print '['+logType+'] ' + message
    with open(logFileName, "a") as logs:
        logs.write('['+scriptName+"][" + logType + "]" + message  + "\n")
        logs.close()
        

def main():
   writeLog("INFO","==============")
   writeLog("INFO","Start Routine")
   writeLog("INFO","==============")

   #AdminApp.update('OnespanServletEAR', 'app', '[  -operation update -contents ' +earPath+'  -nopreCompileJSPs -installed.ear.destination $(APP_INSTALL_ROOT)/DefaultCell01 -distributeApp -nouseMetaDataFromBinary -nodeployejb -createMBeansForResources -noreloadEnabled -nodeployws -validateinstall warn -noprocessEmbeddedConfig -filepermission .*\.dll=755#.*\.so=755#.*\.a=755#.*\.sl=755 -noallowDispatchRemoteInclude -noallowServiceRemoteInclude -asyncRequestDispatchType DISABLED -nouseAutoLink -noenableClientModule -clientMode isolated -novalidateSchema -update.ignore.new -MapModulesToServers [[ EnrollmentServlet EnrollmentServlett.war,WEB-INF/web.xml WebSphere:cell=DefaultCell01,node=DefaultNode01,server=server1 ]]]' )
   try:
       writeLog("INFO","Updating "+applicationName+"...")
       AdminApp.update("blelbalba", 'app', '[-operation update -contents ' + earPath +']')
       writeLog("INFO","Saving "+applicationName+"...")
       AdminConfig.save()
       writeLog("INFO","Starting")
       waitAppStart(applicationName)
   except Exception as e:
      
      writeLog("ERROR",e)
      
main()


