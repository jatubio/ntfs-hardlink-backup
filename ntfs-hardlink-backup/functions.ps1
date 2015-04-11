<#
.DESCRIPTION
	Powershell General Functions
	
	Functions to be used by anothers scripts
	File especially created to be used by the script NTFS-HARDLINK-BACKUP

.NOTES
	Author    : Juan Antonio Tubio <jatubio@gmail.com>
	GitHub    : https://github.com/jatubio
	Date      : 2015/04/09
	Version   : 1.1
#>
#To include only 1 time
$included_functions=$True

Function ShowArray
{
	<#
	.Synopsis
		Show array contents formated.

	.Description
		Write the content of an array in a formated way.
		Can output to screen, to a file and return one string.
		To be used on debug and show info to the user

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/07
		Version   : 1.0

	.Parameter arraytoshow
		Specifies the Array or System.Collections.Hashtable to loop		
	.Parameter filename
		Specifies the path to the output file.
	.Parameter showName
		Instead of show item, show only .Name property
	.Parameter showLength
		Show the length of array
	.Parameter writeHost
		Also write messages to host.

	.Outputs
		String with the content of array in a formated way.

	.Example
		ShowArray $lastBackupFolders "lastBackupFolders.txt" -showName
		-----------
		Loop $lastBackupFolders and write all item.Name on "lastBackupFolders.txt" file

	.Example
		$echo=ShowArray $lastBackupFolders -writeHost
		-----------
		Loop $lastBackupFolders and write all items on host console and return also to
		$echo variable

	#>
	[CmdletBinding()]
	Param(
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[array]$arraytoshow,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$False)]
		[string]$filename,
		[Parameter(Mandatory=$False)]
		[switch]$showName=$False,
		[Parameter(Mandatory=$False)]
		[switch]$showLength=$False,
		[Parameter(Mandatory=$False)]
		[switch]$writeHost=$False
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		$summary=""
		if($writeHost -eq $True) {Write-Host ""}
		foreach($item in $arraytoshow)
		{
			if($showName -eq $True) {
				$echo=$item.Name
			} else {
				$echo=$item
			}
			if($writeHost -eq $True) {Write-Host $echo}
			$summary+=$echo+"`n"
		}
		
		if($showLength -eq $True)
		{
			$echo=("`nTotal Items: " + ($arraytoshow.length))
			$summary+=$echo
			if($writeHost -eq $True) {Write-Host $echo}
		}

		if($filename) { echo $summary > $filename }
		
		return "`n"+$summary		
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function GetFolderDate
{
	<#
	.Synopsis
		Returns The DateTime of a Folder Backup

	.Description
		Gets the name of a folder backup and returns its DateTime 

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/07
		Version   : 1.0

	.Parameter foldername
		Specifies the folder name with format "Name - YYYY-MM-DD HH-MM-SS"

	.Outputs
		DateTime

	.Example
		GetFolderDate $folderName
		-----------
		Returns DateTime of folder in the format set on windows

	.Example
		GetFolderDate "Test Folder - 2014-08-11 10-18-20"
		-----------
		Returns DateTime of folder (08/11/2014 10:18:20)

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$folderName
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

			# Format Name of folder on a correct DateTime Format replacing "-" with ":" in the TimeStamp
		$folderDate=(($folderName.Substring($folderName.length - 19 , 11)) + ( $folderName.Substring($folderName.length - 8) -replace "-",":" ))
		$folderDate=(Get-Date $folderDate)
		
		return $folderDate
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function GetTimeSpanFolders
{
	<#
	.Synopsis
		Returns an HashTable with the backup folders to keep for a time span

	.Description
		Get the max number of folders to keep and the time span for each item and
		Returns an HashTable with the backup folders to keep for a time span

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/07
		Version   : 1.0

	.Parameter folders
		One array of backup folders names (Sorted from most recent to older)
	.Parameter every
		Time span for each item. (In days by default)
	.Parameter maxItems
		Max number of items to keep
	.Parameter format
		Format of every ("minutes","hours","days","months" or "years")
		Default to days.
	.Parameter fixedTime
		If fixedTime, we use last time span date to calculate next 'time span' 
		to next backup item. Default to False
		Else, we use last keeped backup item date.
	.Parameter minutes
		Take every parameter as minutes
	.Parameter hours
		Take every parameter as hours
	.Parameter days
		Take every parameter as days
	.Parameter months
		Take every parameter as months
	.Parameter years
		Take every parameter as years

	.Outputs
		lastBackupsToKeep Hash

	.Example
		$DailyFolders=GetTimeSpanFolders $lastBackupFolders 10 4 -hours
		-----------
		Returns Hash of folders to keep with a backup each 10 hours and maximum 4 folders to keep

	.Example
		$AnnuallyFolders=GetTimeSpanFolders $lastBackupFolders 6 10 -months
		-----------
		Returns Hash of folders to keep with a backup each 6 months and maximum 10 folders to keep

	#>
	[CmdletBinding()]
	Param(
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$folders,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Int32]$every,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Int32]$maxItems,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$False)]
		[string]$format="days",
		[Parameter(Mandatory=$False)]
		[switch]$fixedTime,
		[Parameter(Mandatory=$False)]
		[switch]$minutes,
		[Parameter(Mandatory=$False)]
		[switch]$hours,
		[Parameter(Mandatory=$False)]
		[switch]$days,
		[Parameter(Mandatory=$False)]
		[switch]$months,
		[Parameter(Mandatory=$False)]
		[switch]$years
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
		
		$lastBackupsToKeep=@()
		
		if($years) {
			$format="years"
		} elseif($months) {
			$format="months"
		} elseif($days) {
			$format="days"
		} elseif($hours) {
			$format="hours"
		} elseif($minutes) {
			$format="minutes"
		}

		#Write-Host("`nKeeping $maxItems backups, each every $every ($format)")

		# Let's calculate dates back
		$every=$every * -1

		$spanDateTime=AddDateTime (Get-Date) $every $format
		#Write-Host("Start datetime: " + ($spanDateTime))

			#Loop through each item checking if it's inside of span time
			#From newest to farthest
		foreach($folderName in $folders) 
		{
			$folderDate=GetFolderDate $folderName

			if($lastBackupsToKeep.length -lt $maxItems)
			{
				if($folderDate -lt $spanDateTime)
				{
					# When we get the first item out of range, we get the closest found between the last and current.
					if($lastFolder)
					{
						#Write-Host("Difference between the last ($lastDate) it's " + ($lastDate - $spanDateTime))
						#Write-Host("Difference between the current ($folderDate) it's " + ($spanDateTime - $folderDate))

							# If the current is closer, we get them
						if(($lastDate - $spanDateTime) -gt ($spanDateTime - $folderDate))
						{
							$lastBackupsToKeep+=$folderName
							$lastDate=$folderDate
						}
						else
						{	
							$lastBackupsToKeep+=$lastFolder		#Else, we get the last
						}
					}
					else
					{
						# If we haven't lastFolder, we get current
						$lastBackupsToKeep+=$folderName
						$lastDate=$folderDate
					}
					
					#Write-Host("Taken " + $lastBackupsToKeep[-1])
					
					#If fixed time, we add 'every' time span to last time span date
					if($fixedTime -eq $True)
					{
						$spanDateTime=AddDateTime (Get-Date $spanDateTime) $every $format
					} 
					else  #Else, we add 'every' time span to last keeped item date
					{
						$spanDateTime=AddDateTime (Get-Date $lastDate) $every $format
					}
						
					#Write-Host("*(" + $lastBackupsToKeep.length +")* new datetime: " + ($spanDateTime) + "`n")
				}

					#If we have taken current, reset last to don't take them again
				if($lastDate -eq $folderDate)
				{
					$lastFolder=""
					$lastDate=""
				}
				else
				{
					$lastFolder=$folderName
					$lastDate=$folderDate
				}
			}
			else
			{
				break
			}			
		}
		
		#Write-Host "`n"
		return $lastBackupsToKeep
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function AddDateTime
{
	#Auxiliar function used by GetTimeSpanFolders
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[DateTime]$time,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Int32]$every,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$format
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
		
		if($format -eq "years") {
			return ($time).AddYears($every)
		} elseif($format -eq "months") {
			return ($time).AddMonths($every)
		} elseif($format -eq "days") {
			return ($time).AddDays($every)
		} elseif($format -eq "hours") {
			return ($time).AddHours($every)
		} elseif($format -eq "minutes") {
			return ($time).AddMinutes($every)
		}

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}	

Function DeleteFolder
{
	<#
	.Synopsis
		Delete one backup folder

	.Description
		Delete one backup folder using ln.exe --deeppathdelete parameter

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/07
		Version   : 1.0

	.Parameter foldername
		Specifies the folder name to delete

	.Outputs
		Nothing

	.Example
		DeleteFolder $folderName

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$folderName
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		`cmd /c  "`"`"$lnPath`"  --deeppathdelete `"$folderName`" $logFileCommandAppend`""`
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function GetAllBackupsSourceItems
{
	<#
	.Synopsis
		Get collection of backups items belonging source.

	.Description
		Extracted code from International-Nepal-Fellowship original version
		Loop all folders on backup destination directory and filter by backup
		source folder name
	
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>				
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/09
		Version   : 1.0

	.Backwards Compatibility
		International-Nepal-Fellowship original version work with folder items.
		I have changed here to return only collection of names, no more folder items.
	
	.Parameter BackupDestination
		$selectedBackupDestination

	.Parameter EscapedBackupSourceFolder
		$backup_source_folder escaped
		If not provided, it will take all folders "backup type"

	.Outputs
		Hashtable lastBackupFolders

	.Example
		$oldBackupFolders=@(GetAllBackupsSourceItems $selectedBackupDestination $backup_source_folder_escaped)
		-----------
		Gets all folders of backups belonging to $backup_source_folder_escaped in $selectedBackupDestination folder

	.Example
		$oldBackupFolders=@(GetAllBackupsSourceItems $selectedBackupDestination)
		-----------
		Gets all folders of 'backups type' in $selectedBackupDestination folder
	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$BackupDestination,
		[Parameter(Mandatory=$False)]
		[ValidateNotNullOrEmpty()]
		[String]$EscapedBackupSourceFolder
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		# Contains the list of folders inside backup destination folder
		$oldBackupItems = Get-ChildItem -Force -Path $BackupDestination | Where-Object {$_ -is [IO.DirectoryInfo]} | Sort-Object -Property Name

		# Contains the list of the backups belonging to source
		$lastBackupFolders = @()
		
		if(!$EscapedBackupSourceFolder)
		{
			$matchString = '\w+'
		}
		else
		{
			$matchString = $EscapedBackupSourceFolder
		}			
		$matchString = '^'+ $matchString + ' - (\d{4})-\d{2}-\d{2} \d{2}-\d{2}-\d{2}$' 
		foreach ($item in $oldBackupItems) 
		{
			if ($item.Name  -match $matchString ) {
				$lastBackupFolders += $item.name
			}
		}
		
		return $lastBackupFolders
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function DeleteBackupFolders
{
	<#
	.Synopsis
		Delete a collection of Backup Folders.

	.Description
		If collection have no elements, show one message with
		'No old backups were deleted'

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/10
		Version   : 1.1

	.Parameter backupDestination
		Path of backup destination folder

	.Parameter backupsToDelete
		Specifies the collection with backup folders to delete

	.Parameter dryrun
		Simulation Mode.  Not do any writing on the hard disk, instead it 
		will just report the actions it would have taken.

	.Outside Scope Variables
		Reads Parameters $EchoVerbose,$LogVerbose
	
	.Outputs
		Nothing

	.Example
		DeleteBackupFolders $selectedBackupDestination $backupFolders

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$backupDestination,
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$backupsToDelete,
		[Parameter(Mandatory=$False)]
		[switch]$dryrun=$True
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		$log=""
		
		if($dryrun -eq $True)
		{
			$echo="Simulation Mode: No backup folder(s) will be damaged :)"
			$log+="`r`n$echo`r`n`r`n"
			Write-Host "`n$echo`n"
		}
		
		if($backupsToDelete.length -gt 0)
		{
			$echo=("Deleting " + $backupsToDelete.length + " old backup(s)`n")
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			if($EchoVerbose) { Write-Host $echo }
			if($LogVerbose) { $log+="`r`n$echo" }
			
			foreach($folder in $backupsToDelete)
			{
				$folderToDelete =  $backupDestination +"\"+ $folder

				$echo="Deleting $folderToDelete"
				if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
				if($EchoVerbose) { Write-Host $echo }
				if($LogVerbose) { $log+="`r`n$echo" }
				
				if($dryrun -eq $False)
				{
					DeleteFolder "$folderToDelete"
				}
			}

			$echo="Deleted " + $backupsToDelete.length +" old backup(s)`n"
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			Write-Host "`n$echo"
			$log+="`r`n$echo"
		}
		else
		{
			$echo="No old backups were deleted"
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			Write-Host "`n$echo"
			$log+="`r`n$echo"
		}

		WriteLog $log
		$emailBody = $emailBody + $log

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function WriteLog
{
	<#
	.Synopsis
		Write text in log file

	.Description

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/10
		Version   : 1.0

	.Parameter text
		Specifies the text to write on log file

	.Outputs
		Nothing

	.Outside Scope Variables
		$LogFile
	
	.Example
		WriteLog "testing"

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$text
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		if ($LogFile) {
			$text | Out-File "$LogFile"  -encoding ASCII -append
		}
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function DeleteLogFiles
{
	<#
	.Synopsis
		Get a collection of folders names (or only with date-time strings) and delete
		the log file belonging to them

	.Description
		If collection have no elements, show one message with
		'No old logfiles were deleted'

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/10
		Version   : 1.0

	.Parameter logFileDestination
		Path of logs destination folder

	.Parameter folderNames
		Specifies the collection with backup folders to delete

	.Parameter dryrun
		Simulation Mode.  Not do any writing on the hard disk, instead it 
		will just report the actions it would have taken.

	.Outputs
		Nothing

	.Example
		DeleteLogFiles $logFileDestination $backupsToDelete

	.Example
		DeleteLogFiles $logFileDestination $lastLogFiles

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$logFileDestination,
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$folderNames,
		[Parameter(Mandatory=$False)]
		[switch]$dryrun=$False
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		$log=""
		
		if($dryrun -eq $True)
		{
			$echo="Simulation Mode: No log file(s) will be damaged :)"
			$log+="`r`n$echo`r`n`r`n"
			Write-Host "`n$echo`n"
		}
		
		$echoDeleted=""
		$logDeleted=""
		$logFilesDeleted=0
		if($folderNames.length -gt 0)
		{
			foreach($folder in $folderNames)
			{
				$logFileToDelete=$folder
				#if it's a full backup name folder, get only date-time part.
				if($logFileToDelete.length -gt 19)
				{
					$logFileToDelete=$logFileToDelete.Substring($logFileToDelete.length - 19)
				}				
				$logFileToDelete =  $logFileDestination +"\"+ $logFileToDelete + ".log"

				$echo=""
				If (Test-Path "$logFileToDelete") 
				{
					$logFilesDeleted++
					$echo="Deleting $logFileToDelete"
					if($dryrun -eq $False)
					{
						Remove-Item "$logFileToDelete"
					}
				}
				
				If (Test-Path "$logFileToDelete.zip") 
				{
					$logFilesDeleted++
					if($echo)
					{
						$echo+=" and (.zip)"
					}
					else
					{
					$echo="Deleting $logFileToDelete.zip"
					}

					if($dryrun -eq $False)
					{
						Remove-Item "$logFileToDelete.zip"
					}
				}
				
				if($echo)
				{
					if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
					$logDeleted+="`r`n$echo"
					$echoDeleted+="$echo`n"
				}
			}
		}

		if($logFilesDeleted -gt 0)
		{
			$echo=("Deleting " + $logFilesDeleted + " old log file(s)")
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			if($LogVerbose) 
			{ 
				$log+="$echo`r`n"
				$log+="`r`n$logDeleted"
			}
			
			if($EchoVerbose) 
			{ 
				$echo+="`n`n$echoDeleted"
				Write-Host "$echo"
			}

			$echo="Deleted " + $logFilesDeleted +" old log files(s)"
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			Write-Host "`n$echo"
			$log+="`r`n$echo"
		}
		else
		{
			$echo="No old log files were deleted"
			if($dryrun -eq $True) {$echo="**Simulated** "+$echo}
			Write-Host "`n$echo"
			$log+="`r`n$echo"
		}

		WriteLog $log
		$emailBody = $emailBody + $log

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function GetAllLogsFiles
{
	<#
	.Synopsis
		Get collection of log files on logFileDestination folder

	.Description
	
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>				
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/10
		Version   : 1.0

	.Backwards Compatibility
		International-Nepal-Fellowship original version work with file items.
		I have changed here to return only collection of names, no more file items.
	
	.Parameter logFileDestination
		Path of logs destination folder

	.Outputs
		Hashtable lastLogFiles

	.Example
		$lastLogFiles=GetAllLogsFiles $logFileDestination

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$logFileDestination
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		$lastLogFiles = @()
		# Contains the list of files inside logs destination folder
		If (Test-Path $logFileDestination -pathType container) {
			$oldLogItems = Get-ChildItem -Force -Path $logFileDestination | Where-Object {$_ -is [IO.FileInfo]} | Sort-Object -Property Name

			# get me the old logs if any
			foreach ($item in $oldLogItems) {
				if ($item.Name  -match '^(\d{4}-\d{2}-\d{2} \d{2}-\d{2}-\d{2}).log(.zip)*$' ) {
					$lastLogFiles += $matches[1]
				}
			}
		}
		
		return $lastLogFiles
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function GetOrphanLogFiles
{
	<#
	.Synopsis
		Gets a collection of log files and check if exist his belonging backup folder

	.Description
		If we wan't delete log files of existing backup folders, can use
		this function to filter logFilesToDelete Collection

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.0

	.Parameter backupDestination
		Path of backup destination folder

	.Parameter logFilesToDelete
		Specifies the collection with log files to delete
		Can be only date and time or include also belonging
		folder name.

	.Outputs
		Nothing

	.Example
		$logFilesToDelete = @(GetOrphanLogFiles $selectedBackupDestination $logFilesToDelete)

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$backupDestination,
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$logFilesToDelete
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		# Get all of backup folders
		$backupFolders=@(GetAllBackupsSourceItems $backupDestination)
		
		$orphanLogs=@()
		# Loop logFilesToDelete and find for a belonging backup folder
		foreach($logFile in $logFilesToDelete)
		{			
			$beforeLength=$backupFolders.length
			if($beforeLength -gt 0)
			{
				#if it's a full backup name folder, get only date-time part.
				$logDateTime=$logFile
				if($logDateTime.length -gt 19)
				{
					$logDateTime=$logDateTime.Substring($logDateTime.length - 19)
				}				
					# We catch only the folders that are not matching the logfile date
				$backupFolders=$backupFolders -notlike "* - $logDateTime"
				
					# If not have excluded folders, don't exists backups belonging this logfile
				if($backupFolders.length -eq $beforeLength)
				{
					$orphanLogs+=$logFile
				}
			}
			else
			{
				# If no more backups folders, logFile comes directly to orphanLogs
				$orphanLogs+=$logFile
			}			
		}
		
		return $orphanLogs
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function ArrayFilter
{
	<#
	.Synopsis
		Filter one Array with another array

	.Description
		Given $sourcearray and $filterarray, returns a new array
		with $sourcearray elements not found on filterarray.
		Elements of returned array will be strings
		
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.0

	.Parameter sourcearray
		Source array to be filtered

	.Parameter filterarray
		Array with elements to exclude from sourcearray

	.Outputs
		Array filtered

	.Example
		foldersToKeep = @(ArrayFilter $foldersFound $foldersToDelete)

	#>
	[CmdletBinding()]
	Param(
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$sourcearray,
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$filterarray
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
 
		$matchinfo = $sourcearray | select-string -pattern $filterarray -simplematch -notmatch

		#Filtering will return Selected.Microsoft.PowerShell.Commands.MatchInfo objects, an we need one array of strings
		$filteredarray=@()
		foreach($item in $matchinfo)
		{		
			$filteredarray+=$item.ToString()
		}
		
		return $filteredarray
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function WaitForKey
{
	<#
	.Synopsis
		Show "Press any key to continue ..." and Wait until a key is pressed

	.Description
		Can show a text before waiting 
		
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.0

	.Parameter text
		Text to show

	.Outputs
		Nothing

	.Example
		WaitForKey "Debug messages"

	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$False)]
		[String]$text
	)

	Process
    {
		if($text) { Write-Host $text }
		Write-Host "Press any key to continue ..."	
		$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

Function StepCounter
{
	<#
	.Synopsis
		Keeps one incremental StepCounter and shows one text
		about next step process.		

	.Description
		Based on original source code.
		Will show datetime stamp if global parameter $StepTiming is on
	
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>				
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.0

	.Parameter text
		Text to show

	.Parameter counter
		Value to set the counter

	.Outside Scope Variables
		Reads Parameter $StepTiming
		
	.Outputs
		Nothing

	.Example
		StepCounter "Deleting log file(s)"

	.Example
		StepCounter "Starting" 1
		------
		Set the counter to 1 and show "1. Starting"

	.Example
		StepCounter 1
		------
		Set the counter to 1, not show nothing

	#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$False)]
		[String]$text,
		[Parameter(Mandatory=$False)]
		[Int32]$counter
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		if($counter)
		{
			$script:static_stepCounter=$counter
		}

		if($script:static_stepCounter -le 1)
		{
			$script:static_stepCounter=1
		}
		
		if($text)
		{			
			if ($StepTiming -eq $True) {
				$stepTime = get-date -f "yyyy-MM-dd HH-mm-ss"
			}
			$echo="`n$script:static_stepCounter. $stepTime $text`n"
			
			Write-Host "$echo"
			WriteLog "$echo"

			$script:static_stepCounter++
		}
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function Verbose
{
	<#
	.Synopsis
		Check for $EchoVerbose and $LogVerbose and show text on screen/log file

	.Description

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.0

	.Parameter text
		Specifies the text to show/write on log file

	.Outputs
		Nothing

	.Outside Scope Variables
		Reads Parameters $EchoVerbose,$LogVerbose
	
	.Example
		Verbose "This is a verbose message"

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$text
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		if($EchoVerbose)
		{
			Write-Host $text
		}

		if($LogVerbose)
		{
			WriteLog "$text"
		}
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}