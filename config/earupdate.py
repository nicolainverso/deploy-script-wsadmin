def waitAppStart(appName,maxRetry,timeToWaitStartup):
    count = 0    
    while AdminApp.isAppReady(appName) and count < maxRetry:
       count = count + 1
       writeLog("INFO","Check:" + count)
       time.sleep(timeToWaitStartup)
       
    if count==(maxRetry-1):
       writeLog("ERROR","Startup failed")

def writeLog(logType,message,scriptName):
    print '['+logType+'] ' + message
    with open(logFileName, "a") as logs:
        logs.write('['+scriptName+"][" + logType + "]" + message  + "\n")
        logs.close()
        

def run(earPath,logFileName,scriptName,applicationName,timeToWaitStartup,maxRetry):
   writeLog("INFO","==============",scriptName)
   writeLog("INFO","Start Routine",scriptName)
   writeLog("INFO","==============",scriptName)

   try:
       writeLog("INFO","Updating "+applicationName+"...",scriptName)
       AdminApp.update(applicationName, 'app', '[-operation update -contents ' + earPath +']')
       writeLog("INFO","Saving "+applicationName+"...",scriptName)
       AdminConfig.save()
       writeLog("INFO","Starting",scriptName)
       waitAppStart(applicationName,maxRetry,timeToWaitStartup)
   except Exception as e:
      writeLog("ERROR",e)
      


