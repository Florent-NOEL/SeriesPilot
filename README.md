# SeriesPilot
PowerShell script to manage series on PowerShell, launch, auto naming and more

# Get started
-> you need vlc installed in your computer

Open your favorite text editor and write the following text at the top of your PowerShell profile file.


Using PowerShell: code $PROFILE
will open your profile file within vscode

1# text at the top of your PowerShell: Import-Module E:\ps1\serie.psm1

2# Edit the videoConfig.json file

{
  "manualFile": "E:\\ps1\\man.txt", -> enter the literal path of the manual file
  "sendVideoPath": "E:\\video", -> enter the literal path of where you want to store your next series
  "listSerieLocations": ["E:\\video"], -> enter the list of paths where your series are
  "cmdletLength": 3 -> number of characters for the serie shortcut 3 is ok
}

3# enter in your powershell: serie man
-> this will show you the available functions

---------

How the app work:

the app read the name of the folders and the name of the episodes inside the specified folder.
In order to make it work all the series need the following structure.

for exemple for Game-of-Thrones

folders specified in config > Game-of-Thrones > s1 > 

got-s1-e1.mkv
got-s1-e2.mkv
got-s1-e3.mkv
...

------
#Optional
you can add Alias in the $PROFILE file to make it even quicker

exemple: use gs instead of serie

New-Alias gs serie

