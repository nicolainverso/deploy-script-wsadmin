import sys
import time

def wsadminToList(inStr):
        outList=[]
        if (len(inStr)>0 and inStr[0]=='[' and inStr[-1]==']'):
                tmpList = inStr[1:-1].split() #splits space-separated lists,
        else:
                tmpList = inStr.split("\n")   #splits for Windows or Linux
        for item in tmpList:
                item = item.rstrip();         #removes any Windows "\r"
                if (len(item)>0):
                        outList.append(item)
        return outList
#endDef

def installPortalApp(earFileName, appName, cellName, clusterName, installOptions):
  #--------------------------------------------------------------
  # set up globals
  #--------------------------------------------------------------
  global AdminApp
  global AdminControl
  global AdminConfig
  global Help

  installOptions.append('-appname')
  installOptions.append(appName)

  # Should we install on a cluster?
  if len(clusterName) != 0: 
    appServer = 'WebSphere:cell=' + cellName + ',cluster=' + clusterName

    mapModuleOptions = [[ '.*', '.*', appServer ]] 

    # Append additional options
    installOptions.append('-cluster')
    installOptions.append(clusterName)
    AdminApp.install(earFileName, installOptions)
    AdminConfig.save( )

    count = 0

    # This is probably not necessary 
    while not AdminApp.isAppReady(appName) and count < 10:
      count = count + 1
      print 'Waiting for app to be ready ' + count + ' of 10'
      time.sleep(10)
    #endWhile

    clusterId = AdminConfig.getid('/ServerCluster:' + clusterName + '/' )
    print 'clusterId' + clusterId
    clusterMembers = wsadminToList(AdminConfig.list('ClusterMember', clusterId))

    for member in clusterMembers:
      print 'startApplication on member ' + str(member)
      currentServer = AdminConfig.showAttribute(member, 'memberName')
      print 'currentServer ' + currentServer
      currentNodeName = AdminConfig.showAttribute(member, 'nodeName')
      print 'currentNodeName ' + currentNodeName
      query = 'cell=' + cellName + ',node=' + currentNodeName + ',type=ApplicationManager,process=' + currentServer + ',*'
      print 'query ' + query
      appMgr = AdminControl.queryNames(query )
      print appMgr

      Sync1 = AdminControl.completeObjectName('type=NodeSync,node=' + currentNodeName + ',*')
      print 'Sync1 ' + Sync1
      AdminControl.invoke(Sync1, 'sync')
      print 'Node synchronized. Waiting a short while for binary expansion to finish'
      time.sleep(5)
      print 'Starting application'

      AdminControl.invoke(appMgr, "startApplication", appName )
    #endFor
  else:
    appMgr = AdminControl.queryNames("type=ApplicationManager,*" )
    AdminApp.install(earFileName, installOptions)
    AdminConfig.save( )
    AdminControl.invoke(appMgr, "startApplication", appName )
  #endIf   
#endDef

#if (len(sys.argv) != 4 and len(sys.argv) != 5):
#  print len(sys.argv)
#  print "install_application_ear.py: this script requires the following parameters: ear file name, application name, cell name, install options and cluster name (optional)" 
#  sys.exit(1)
#endIf

earFileName = sys.argv[0]
print 'earFileName' + earFileName
appName =  sys.argv[1]
cellName =  sys.argv[2]
installOptions =  eval(sys.argv[3])

clusterName = ""
if len(sys.argv) == 5:
  clusterName =  sys.argv[4]

installPortalApp(earFileName, appName, cellName, clusterName, installOptions)