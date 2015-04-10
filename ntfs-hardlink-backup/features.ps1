<#
.DESCRIPTION
	Features Functions and Code
	
	We extract the code of features separately, and thus facilitate the 
	maintenance of source code.
	File especially created to be used by the script NTFS-HARDLINK-BACKUP

.NOTES
	Author    : Juan Antonio Tubio <jatubio@gmail.com>
	GitHub    : https://github.com/jatubio
	Date      : 2015/04/10
	Version   : 1.0
#>
#To include only 1 time
$included_features=$True

Function GetBackupsToKeepPerYear
{
	<#
	.Synopsis
		Get collection of Backups to keep per year.
		Based on $backupsToKeepPerYear parameter.

	.Description
		Extracted code from International-Nepal-Fellowship original version
	
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>				
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/09
		Version   : 1.0

	.Parameter backupsToKeepPerYear
		Number of Backups to keep per year (From global parameter)
		
	.Parameter oldBackupFolders
		Specifies the Array of older backups folders found belonging to source. ($oldBackupSourceFolders)
		
	.Parameter EscapedBackupSourceFolder
		$backup_source_folder escaped

	.Outputs
		Hashtable with lastBackupFolders to delete, without folders to keep.

	.Outside Scope Variables
		$LogVerbose
	
	.Example
		$lastBackupFolders=GetBackupsToKeepPerYear $backupsToKeepPerYear $oldBackupFolders $backup_source_folder

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Int32]$backupsToKeepPerYear,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Array]$oldBackupFolders,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$EscapedBackupSourceFolder
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		# Contains the list of all the old backups sorted by years
		$lastBackupFoldersPerYear = @{}
		# Contains the list of the backups per year to keep
		$lastBackupFoldersPerYearToKeep = @{}
		# Contains the list of all the old backups to be deleted
		$lastBackupFolders = @()

		$log=""

		$echo=("Found " + $oldBackupFolders.length + " old backup(s)")
		Write-Host "$echo`n"
		$log+="`r`n$echo`r`n"

		$echo="Keeping $backupsToKeepPerYear backup(s) per year."
		if($LogVerbose) {$echo+=" (Parameter backupsToKeepPerYear=$backupsToKeepPerYear)"}

		Write-Host $echo
		$log+="`r`n$echo"
		
		#find all backups per year
		foreach ($folder in $oldBackupFolders) {
			if ($folder  -match '^'+$EscapedBackupSourceFolder+' - (\d{4})-\d{2}-\d{2} \d{2}-\d{2}-\d{2}$' ) {
				if (!($lastBackupFoldersPerYear.ContainsKey($matches[1]))) {
					$lastBackupFoldersPerYear[$matches[1]] = @()
				}
				$lastBackupFoldersPerYear[$matches[1]]+= $folder
			}
		}

		#decide which backups from the last year to keep
		foreach ($year in $($lastBackupFoldersPerYear.keys | sort)) {
			#echo $year
			if (!($lastBackupFoldersPerYearToKeep.ContainsKey($year))) {
				$lastBackupFoldersPerYearToKeep[$year] = @()
			}
			
			# If we want to keep more backups than are actually there then just keep the whole array
			if ($backupsToKeepPerYear -ge $lastBackupFoldersPerYear[$year].length) {
				$lastBackupFoldersPerYearToKeep[$year] = $lastBackupFoldersPerYear[$year]
			} else {
				#calculate the day we ideally would like to have a backup of
				#then find the backup we have that is nearest to that date and keep it
				
				$daysBetweenBackupsToKeep = 365/$backupsToKeepPerYear
				$dayOfYearToKeepBackupOf = 0
				while (($lastBackupFoldersPerYearToKeep[$year].length -lt $backupsToKeepPerYear) -and ($lastBackupFoldersPerYear[$year].length -gt 0)) {
					$dayOfYearToKeepBackupOf = $dayOfYearToKeepBackupOf + $daysBetweenBackupsToKeep
					$previousDaysDifference = 366
					foreach ($backupFolder in $lastBackupFoldersPerYear[$year]) {
						
						$backupFolder  -match '^'+$EscapedBackupSourceFolder+' - (\d{4}-\d{2}-\d{2}) \d{2}-\d{2}-\d{2}$' | Out-Null
						$daysDifference = [math]::abs($dayOfYearToKeepBackupOf-(Get-Date $matches[1]).DayOfYear)

						if ($daysDifference -lt $previousDaysDifference) {
							$bestBackupToKeep=$backupFolder
						}
						$previousDaysDifference = $daysDifference
					}
					
					$lastBackupFoldersPerYearToKeep[$year] +=$bestBackupToKeep
					$lastBackupFoldersPerYear[$year] = $lastBackupFoldersPerYear[$year] -ne $bestBackupToKeep
				}	
			}
			$thisYearBackupsKept = $lastBackupFoldersPerYearToKeep[$year].length
			$yearBackupsKeptText += "Keeping $thisYearBackupsKept backup(s) from $year `r`n"
		}

		# Get Backups Selected For Delete
		foreach ($folder in $oldBackupFolders) {
			if ($folder  -match '^'+$EscapedBackupSourceFolder+' - (\d{4})-\d{2}-\d{2} \d{2}-\d{2}-\d{2}$' ) {
				#if we have that folder in the list of folders to keep do not add it to the list
				#of lastBackupFolders because they will be used for deleting old folders
				if ($lastBackupFoldersPerYearToKeep[$matches[1]] -notcontains $folder) {
					#Backwards Compatibility:: Now $lastBackupFolders have only the name and not the item
					$lastBackupFolders += $folder
				}
			}
		}

		Write-Host "`n$yearBackupsKeptText"
		
		#If LogVerbose, write also on log, keeped folders per year
		if($LogVerbose)
		{
			$yearBackupsKeptText=""
			foreach($item in $lastBackupFoldersPerYearToKeep.getEnumerator() | Sort Value )
			{
				$year=$item.key
				$yearBackupsKeptText += "`r`nKeeping " + $lastBackupFoldersPerYearToKeep[$year].length + " backup(s) from $year `r`n"
				foreach($folder in $lastBackupFoldersPerYearToKeep[$year])
				{
					$yearBackupsKeptText += "`t$folder`r`n"
				}			
			}
		}

		$log+="`r`n$yearBackupsKeptText"

		$echo=("Total kept: " + ($oldBackupFolders.length - $lastBackupFolders.length) + " 'per years' backup(s)")
		Write-Host "$echo`n"
		$log+="`r`n$echo`r`n"
		
		WriteLog $log
		
		return $lastBackupFolders
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function SkipIfNoChanges
{
	<#
	.Synopsis
		Parse log file for changes between source and destination folder
		and delete backup folder if not changes.
		Thus, we get less backup folders and therefore less hard links. 
		Delaying the possibility of reaching the NTFS link limit of 1023.		

	.Description
		We take as changes:
		
			+	Copy/Create an item. 
			*	Hardlink a file
			-	Remove an item from the target that is not present in the source.
	
			In any item type(f,h,s,j,m,d,t,e,p)		
	
		For more information see Output section on http://schinagl.priv.at/nt/ln/ln.html#output

	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/10
		Version   : 1.1

	.Parameter lnLog
		Log returned by ln.exe tool (Collection from a file: $backup_response)

	.Parameter currentBackupFolder
		Full path of current backup folder. ($actualBackupDestination$backupMappedString)

	.Parameter oldBackupSourceFolders
		Specifies the Array of older backups folders found. ($oldBackupSourceFolders)

	.Outputs
		Nothing

	.Outside Scope Variables
	
	.Example
		SkipIfNoChanges $backup_response $actualBackupDestination$backupMappedString $loldBackupSourceFolders

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Array]$lnLog,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$currentBackupFolder,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Array]$oldBackupSourceFolders
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"

		$have_changes=$false

				# We take as changes:
				#
				# +	Copy/Create an item. 
				# *	Hardlink a file
				# -	Remove an item from the target that is not present in the source.
				#
				# In any item type(f,h,s,j,m,d,t,e,p)
				#
				# For more information see Output section on http://schinagl.priv.at/nt/ln/ln.html#output
		foreach ( $line in 1..$lnLog.length ) {	
			if ($lnLog[$line] -match '^(\+|-|\*)(f|h|s|j|m|d|t|e|p)\s[a-z]:\\') {
				$have_changes=$true
				break
			}
		}
				
		$log=""

		if($have_changes -eq $False)
		{
			$echo="ATTENTION: Deleted the current backup ($currentBackupFolder) because no changes since the last backup."
			$log+="`r`n$echo`r`n"
			Write-Host "`n$echo"

			DeleteFolder "$currentBackupFolder"
			
			#Arrays in PowerShell are fixed-size and we can't remove elements.
			#Thus, to remove the last entry in the array, you could overwrite the array by a copy that includes every item except the last
			$oldBackupSourceFolders = $oldBackupSourceFolders[0..($oldBackupSourceFolders.length - 2)]								
		} else {
			$echo="Changes found since the last backup. Keeping the current backup ($currentBackupFolder)."
			$log+="`$echo`r`n"
			Write-Host "$echo"
		}
		
		WriteLog $log

		return $oldBackupSourceFolders
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}