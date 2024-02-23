import os
import shutil
import datetime
import subprocess

originPath = '' #Folder to Backup
tmpDestinationPath = '' #Destination of Copy of Folder to Backup

if os.path.exists(originPath): #Verify if folder and content exist created and then erase it
    os.mkdir(tmpDestinationPath)
    shutil.rmtree(tmpDestinationPath)

shutil.copytree(originPath, tmpDestinationPath) #Copy is created
getNowDate = datetime.datetime.now().strftime('%d%m%Y_at_%H%M%S') #obtain current date
archiveName = f'backup {getNowDate}' #provide name of compress file
filesCompressed = f'{archiveName}' #compressed file name
shutil.make_archive(filesCompressed, 'gztar', tmpDestinationPath) #compress file
if os.path.exists(originPath): #Verify if folder and content exist then erase it
    shutil.rmtree(tmpDestinationPath)
print('Backup created!')

originLocal = '' # Destination folder on local
DestinationServer = '' # Destination folder on server

subprocess.run(['rsync', '-av', originLocal, DestinationServer]) # Rsync
print('Backup Uploaded to Server!')