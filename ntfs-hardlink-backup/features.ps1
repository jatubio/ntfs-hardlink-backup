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
		Specifies the Array of older backups folders found belonging to source. ($lastBackupFolders)
		
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
		[AllowEmptyCollection()]
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

	.Parameter lastBackupFolders
		Specifies the Array of older backups folders found. ($lastBackupFolders)

	.Outputs
		Nothing

	.Outside Scope Variables
	
	.Example
		SkipIfNoChanges $backup_response $actualBackupDestination$backupMappedString $llastBackupFolders

	#>
	[CmdletBinding()]
	Param(
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$lnLog,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[String]$currentBackupFolder,
		[AllowEmptyCollection()]
		[Parameter(Mandatory=$True)]
		[Array]$lastBackupFolders
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
			$lastBackupFolders = $lastBackupFolders[0..($lastBackupFolders.length - 2)]								
		} else {
			$echo="Changes found since the last backup. Keeping the current backup ($currentBackupFolder)."
			$log+="`$echo`r`n"
			Write-Host "$echo"
		}
		
		WriteLog $log

		return $lastBackupFolders
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function ClosestRotation
{
	<#
	.Synopsis
		Rotatory backup folders strategy.
		Get one HashTable with the currents backup folders

	.Description
		Implementation of a custom rotatory backup folders strategy.
		
		Will keep folders on daily, weekly, monthly and annually time spans.
		Mark for delete others.

		You can setup how much long is every span and a max items for each.
		All parameters have hardcoded default values:
			You keep:
				1 most recent backup.
				4 daily backups each every 12 hours.
				8 weekly backups each every half week.
				24 monthly backups each every 15 days.
				6 annually backups each every 6 months.
				1 backup for every year to max 5 years older.
				
			Then you keep a maximum of: 1+4+8+24+6+5=48 backups for a max of 5 years.
		
		All backups are different. Backups are processed in order of: 
			most recent,daily,weekly,monthly,annually,5 years older.
		
		Then, if one backup if marked to keep on daily, it's not available when processing 
		weekly backups.
		
		To elect which backup item to keep, we calculate the next time span and find the older 
		backup inside time span, and the newest backup before time span. We get the closest 
		between both and time span date. If teher is a tie, we get the older backup inside time span.
		
		To calculate next time span, we add the time span interval (by example: every 2 hours).
		Here, you can choose between two strategies: (Choosing which of the two will add that interval)
			- DateTime of the last time span (Parameter -fixedTime to True)
			- DateTime of the last backup item (Parameter -fixedTime to False) (Default strategy)
			
			The difference is that with no -fixedTime, keep backups are best distributed in time.
			By sample:
				If you have current backups items: 12:00,11:46,11:43,11:35,11:29,11:26,10:00,09:00
				And want to keep max of 5 backups for every 10 minutes,

				With -fixedTime, you keep: 12:00,11:46,11:43,11:29,11:26
					(Keep backups closest to 12:00,11:50,11:40,11:30,11:20)
		
				Without -fixedTime, you keep: 12:00,11:46,11:35,11:26,10:00
					(Keep backups closest to 12:00,11:50,11:36,11:25,11:16)
								
	.Notes
		Author    : Juan Antonio Tubio <jatubio@gmail.com>
		GitHub    : https://github.com/jatubio
		Date      : 2015/04/11
		Version   : 1.1

	.Parameter oldBackupFolders
		A lastBackupFolders Hash
	.Parameter recents
		Max number of recent backup(s) to keep
	.Parameter daily
		Three comma separated values: Every,Max,Format
		All are optional
	.Parameter weekly
		Three comma separated values: Every,Max,Format
		All are optional
	.Parameter monthly
		Three comma separated values: Every,Max,Format
		All are optional
	.Parameter annually
		Three comma separated values: Every,Max,Format
		All are optional
	.Parameter maxyears
		Max years to keep backups with 1 item by year.
	.Parameter fixedTime
		If fixedTime, we use last time span date to calculate next 'time span' 
		to next backup item. Default to False
		Else, we use last keeped backup item date.
	.Parameter dryrun
		Simulation Mode. Do not delete backup folders, only show results
		of Backup Strategy.

	You can give 0 for daily,weekly,monthly,annually or maxyears parameter to 
	not keep that time span.
		
	.Example
		$foldersKeeped=ClosestRotation $lastBackupFolders -fixedTime -daily 0 -weekly 7,4
		-----------
		Keep folders using Most Closest Rotation Scheme with "Fixed Time". Don't keep daily snapshots
		and for weekly, keep 4 backups each every 7 days.

	.Example
		$foldersKeeped=ClosestRotation $lastBackupFolders -maxyears 0 -dryrun
		-----------
		Keep folders using Most Closest Rotation Scheme with "Best distributed". Don't keep maxyears
		snapshots. Simulation Mode: Don't remove nothing at all.

	.Example
		ClosestRotation $lastBackupFolders 0 0 0 0 0 -dryrun
		-----------
		Display a funny message

	.Outputs
		This new version don't delete folders, return a collection with folders
		selected to delete.

	#>
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[Array]$oldBackupFolders,
		[Parameter(Mandatory=$False)]
		[Int32]$recents=5,
		[Parameter(Mandatory=$False)]
		[Array]$daily=@(),
		[Parameter(Mandatory=$False)]
		[Array]$weekly=@(),
		[Parameter(Mandatory=$False)]
		[Array]$monthly=@(),
		[Parameter(Mandatory=$False)]
		[Array]$annually=@(),
		[Parameter(Mandatory=$False)]
		[Int32]$maxyears=5,
		[Parameter(Mandatory=$False)]
		[switch]$fixedTime=$False,
		[Parameter(Mandatory=$False)]
		[switch]$dryrun=$False
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing"
		
			#Default values
			#Always will keep at least most recent backup, because it's not in $oldBackupFolders collection and can't reach them
		if($recents -le 0)	{$recents=1}			
		if($daily[0] -ne 0)
		{
			if(!$daily[0]) {$daily+=12}
			if(!$daily[1]) {$daily+=4}
			if(!$daily[2]) {$daily+="hours"}
		} else {
			if(!$daily[0]) {$daily+=0}
			if(!$daily[1]) {$daily+=0}
		}
		if($weekly[0] -ne 0)
		{
			if(!$weekly[0]) {$weekly+=84}
			if(!$weekly[1]) {$weekly+=8}
			if(!$weekly[2]) {$weekly+="hours"}
		} else {
			if(!$weekly[0]) {$weekly+=0}
			if(!$weekly[1]) {$weekly+=0}
		}
		if($monthly[0] -ne 0)
		{
			if(!$monthly[0]) {$monthly+=15}
			if(!$monthly[1]) {$monthly+=24}
			if(!$monthly[2]) {$monthly+="days"}
		} else {
			if(!$monthly[0]) {$monthly+=0}
			if(!$monthly[1]) {$monthly+=0}
		}
		if($annually[0] -ne 0)
		{
			if(!$annually[0]) {$annually+=6}
			if(!$annually[1]) {$annually+=6}
			if(!$annually[2]) {$annually+="months"}
		} else {
			if(!$annually[0]) {$annually+=0}
			if(!$annually[1]) {$annually+=0}
		}
		
		$echo="`nUsing Closest Rotation Scheme to remove older backups.`n"
		if($fixedTime -eq $True)
		{
			$echo+="`tFixed Time chosen strategy`n"
		}
		else
		{
			$echo+="`tBest Distribution chosen strategy`n"
		}

		Write-Host $echo
		$log=$echo

			# Validate parameters
		if(($daily[0] -eq 0) -and ($weekly[0] -eq 0) -and ($monthly[0] -eq 0) -and ($annually[0] -eq 0))
		{
			$echo="With these parameters, I would delete most of backup folders. Are you kidding?"
			Write-Host $echo
			$log+=$echo
			
			WriteLog $log

			return $oldBackupFolders
		}

		$echo="Strategy Parameters:`n"
		if($recents -ne 0){$echo+=("`tKeep $recents most recent(s) backup(s)`n")}
		if($daily[0] -ne 0){$echo+=("`tDaily: Keep "+$daily[1]+" backup(s), each every "+$daily[0]+" "+$daily[2]+"`n")}
		if($weekly[0] -ne 0){$echo+=("`tWeekly: Keep "+$weekly[1]+" backup(s), each every "+$weekly[0]+" "+$weekly[2]+"`n")}
		if($monthly[0] -ne 0){$echo+=("`tMonthly: Keep "+$monthly[1]+" backup(s), each every "+$monthly[0]+" "+$monthly[2]+"`n")}
		if($annually[0] -ne 0){$echo+=("`tAnnually: Keep "+$annually[1]+" backup(s), each every "+$annually[0]+" "+$annually[2]+"`n")}
		if($maxyears -ne 0){$echo+=("`tKeep 1 backup(s), every year to max of "+$maxyears+" year(s)older `n")}
				
		$log+=$echo
		
		if($dryrun -eq $True)
		{
			$echo="`nSimulation Mode: No backup folder(s) will be damaged :)`n`n"
			$log+=$echo
			Write-Host $echo
		}

		$allBackups=@()
		$backupsToDelete=@()
		
			#First, get one array only with names
			#Loop through each item from newest to farthest
			#We need to change natural order and give in descent order
		for ($i=$oldBackupFolders.length - 1; $i -ge 0; $i-- ) {
			$allBackups+=$oldBackupFolders[$i]
		}
		
		$echo=("Found " + ($allBackups.length + 1) + " regular backup(s), keeping a maximum of " + ($recents+$daily[1]+$weekly[1]+$monthly[1]+$annually[1]+$maxyears) + " regular backup(s)`n")
		$log+=$echo
		Write-Host $echo

		# Remove most recents backups
		# The current/most recent backup isn't in the array
		if($recents -gt 0)
		{
			if($recents -gt 1)
			{
				$lastBackupFolders = $lastBackupFolders[($recents-1)..($lastBackupFolders.length - 1)]
			}
			$echo=("`nKeeping " + $recents + " recents backup(s)`n")
		}

			# Daily snapshots
		if($daily[0] -ne 0)
		{
			$echo=("Choosing the Daily backup(s) to keep: max "+$daily[1]+" backup(s), each every "+$daily[0]+" "+$daily[2])
			# If Array have only 1 element it's returned as string. Thus, i will force cast to array wrapping the function between @()
			$backupsToKeep=@(GetTimeSpanFolders $allBackups $daily[0] $daily[1] -format $daily[2])

			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
						
			$log+=ShowArray $backupsToKeep -writeHost:$dryrun

			$echo=("`nKeeping " + $backupsToKeep.length + " Daily backup(s)`n")
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
			
			$allBackups=@(ArrayFilter $allBackups $backupsToKeep)
		}
		
			# Weekly snapshots
		if($weekly[0] -ne 0)
		{
			$echo=("Choosing the Weekly backup(s) to keep: max "+$weekly[1]+" backup(s), each every "+$weekly[0]+" "+$weekly[2])
			$backupsToKeep=@(GetTimeSpanFolders $allBackups $weekly[0] $weekly[1] -format $weekly[2])
			
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
						
			$log+=ShowArray $backupsToKeep -writeHost:$dryrun

			$echo=("`nKeeping " + $backupsToKeep.length + " Weekly backup(s)`n")
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
			
			$allBackups=@(ArrayFilter $allBackups $backupsToKeep)
		}

			# Monthly snapshots
		if($monthly[0] -ne 0)
		{
			$echo=("Choosing the Monthly backup(s) to keep: max "+$monthly[1]+" backup(s), each every "+$monthly[0]+" "+$monthly[2])
			$backupsToKeep=@(GetTimeSpanFolders $allBackups $monthly[0] $monthly[1] -format $monthly[2])

			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
						
			$log+=ShowArray $backupsToKeep -writeHost:$dryrun

			$echo=("`nKeeping " + $backupsToKeep.length + " Monthly backup(s)`n")
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
			
			$allBackups=@(ArrayFilter $allBackups $backupsToKeep)
		}

			# Annually snapshots
		if($annually[0] -ne 0)
		{
			$echo=("Choosing the Annually backup(s) to keep: max "+$annually[1]+" backup(s), each every "+$annually[0]+" "+$annually[2])
			$backupsToKeep=@(GetTimeSpanFolders $allBackups $annually[0] $annually[1] -format $annually[2])

			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
						
			$log+=ShowArray $backupsToKeep -writeHost:$dryrun

			$echo=("`nKeeping " + $backupsToKeep.length + " Annually backup(s)`n")
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
			
			$allBackups=@(ArrayFilter $allBackups $backupsToKeep)
		}

			# Max Years
		if($maxyears -ne 0)
		{
			$echo=("Choosing the Max years backup(s) to keep: max "+$maxyears+" backup(s), each every 1 years")
			$backupsToKeep=@(GetTimeSpanFolders $allBackups $maxyears 1 -format "years")

			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
						
			$log+=ShowArray $backupsToKeep -writeHost:$dryrun

			$echo=("`nKeeping " + $backupsToKeep.length + " Max years backup(s)`n")
			if($dryrun -eq $True) { Write-Host $echo }
			$log+=$echo+"`n"
			
			$allBackups=@(ArrayFilter $allBackups $backupsToKeep)
		}

		#Backups to delete
		$backupsToDelete=$allBackups

		WriteLog $log

		$emailBody = $emailBody + $log

		return $backupsToDelete

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing"
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}