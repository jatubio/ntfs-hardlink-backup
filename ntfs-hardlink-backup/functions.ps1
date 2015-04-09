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
		[ValidateNotNullOrEmpty()]
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
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"

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
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
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
		Returns the name of a folder backup and returns its DateTime 

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
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"

			# Format Name of folder on a correct DateTime Format replacing "-" with ":" in the TimeStamp
		$folderDate=(($folderName.Substring($folderName.length - 19 , 11)) + ( $folderName.Substring($folderName.length - 8) -replace "-",":" ))
		$folderDate=(Get-Date $folderDate)
		
		return $folderDate
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
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
		backupsToKeep Hash

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
		[ValidateNotNullOrEmpty()]
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
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"
		
		$backupsToKeep=@()
		
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

			if($backupsToKeep.length -lt $maxItems)
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
							$backupsToKeep+=$folderName
							$lastDate=$folderDate
						}
						else
						{	
							$backupsToKeep+=$lastFolder		#Else, we get the last
						}
					}
					else
					{
						# If we haven't lastFolder, we get current
						$backupsToKeep+=$folderName
						$lastDate=$folderDate
					}
					
					#Write-Host("Taken " + $backupsToKeep[-1])
					
					#If fixed time, we add 'every' time span to last time span date
					if($fixedTime -eq $True)
					{
						$spanDateTime=AddDateTime (Get-Date $spanDateTime) $every $format
					} 
					else  #Else, we add 'every' time span to last keeped item date
					{
						$spanDateTime=AddDateTime (Get-Date $lastDate) $every $format
					}
						
					#Write-Host("*(" + $backupsToKeep.length +")* new datetime: " + ($spanDateTime) + "`n")
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
		return $backupsToKeep
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
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
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"
		
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

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
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
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"

		`cmd /c  "`"`"$lnPath`"  --deeppathdelete `"$folderName`" $logFileCommandAppend`""`
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}