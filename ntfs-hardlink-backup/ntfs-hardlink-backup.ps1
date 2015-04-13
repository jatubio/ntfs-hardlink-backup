<#
.DESCRIPTION
	NTFS-HARDLINK-BACKUP Version: 2.0.BETA.4
	
	This software is used for creating hard-link-backups.
	The real magic is done by DeLoreanCopy of ln: http://schinagl.priv.at/nt/ln/ln.html	So all credit goes to Hermann Schinagl.
	INSTALLATION:
	1. Read the documentation of "ln" http://schinagl.priv.at/nt/ln/ln.html
	2. Download "ln" and unpack the file.
	3. Download and place ntfs-hardlink-backup.ps1 into .\bat directory below the ln program
	4. Navigate with Explorer to the .\bat folder
	5. Right Click on the ntfs-hardlink-backup.ps1 file and select "Properties"
	6. If you see in the bottom something like "Security: This file came from an other computer ..." Click on "Unblock"
	7. Start powershell from windows start menu (you need Windows 7 or Win Server for that, on XP you would need to install PowerShell 2 first)
	8. Allow local non-signed scripts to run by typing "Set-ExecutionPolicy RemoteSigned"
	9. Run ntfs-hardlink-backup.ps1 with full path
.SYNOPSIS
	c:\full\path\bat\ntfs-hardlink-backup.ps1 <Options>
.PARAMETER iniFile
	Path to an optional INI file that contains any of the parameters.
.PARAMETER backupSources
	Source path of the backup. Can be a list separated by comma.
.PARAMETER backupDestination
	Path where the data should go to. Can be a list separated by comma.
	The first destination that exists and, if localSubnetOnly is on, is in the local subnet, will be used.
	The backup is only ever really done to 1 destination.
.PARAMETER subst
	Drive letter to substitute (subst) for the path specified in backupDestination.
	Often useful if a NAS or other device is a problem when accessed directly by UNC path.
	Sometimes if a drive letter is substituted for the UNC path then things work.
.PARAMETER backupsToKeep
	How many backup copies should be kept. All older backups and their log files will be deleted. 1 means mirror. Default=50
.PARAMETER backupsToKeepPerYear
	How many backup copies of every year should be kept. This will add to the number of backupsToKeep. Default=0
.PARAMETER timeTolerance
	Sometimes useful to not have an exact timestamp comparison between source and dest, but kind of a fuzzy comparison, because the system time of NAS drives is not exactly synced with the host.
	To overcome this we use the -timeTolerance switch to specify a value in milliseconds.
.PARAMETER excludeFiles
	Exclude files via wildcards. Can be a list separated by comma.
.PARAMETER excludeDirs
	Exclude directories via wildcards. Can be a list separated by comma.
.PARAMETER traditional
	Some NAS boxes only support a very outdated version of the SMB protocol. SMB is used when network drives are connected. This old version of SMB in certain situations does not support the fast enumeration methods of ln.exe, which causes ln.exe to simply do nothing.
	To overcome this use the -traditional switch, which forces ln.exe to enumerate files the old, but a little slower way.
.PARAMETER noads
	The -noads option tells ln.exe not to copy Alternative Data Streams (ADS) of files and directories.
	This option can be useful if the destination supports NTFS, but can not deal with ADS, which happens on certain NAS drives.
.PARAMETER noea
	The -noea option tells ln.exe not to copy EA Records of files and directories.
	This option can be useful if the destination supports NTFS, but can not deal with EA Records, which happens on certain NAS drives.
.PARAMETER splice
	Splice reconnects Outer Junctions/Symlink directories in the destination to their original targets.
	see http://schinagl.priv.at/nt/ln/ln.html#splice
.PARAMETER backupModeACLs
	Using the Backup Mode ACLs aka Access Control Lists, which contain the security for Files, Folders, Junctions or SymbolicLinks, and Encrypted Files are also copied.
	see http://schinagl.priv.at/nt/ln/ln.html#backup
.PARAMETER localSubnetOnly
	Switch on to only run the backup when the destination is a local disk or a server in the same subnet.
	This is useful for scheduled network backups that should only run when the laptop is on the home office network.
.PARAMETER localSubnetMask
	The IPv4 netmask that covers all the networks that should be considered local to the backup destination IPv4 address.
	Format like 255.255.255.0 (24 bits set) 255.255.240.0 (20 bits set)  255.255.0.0 (16 bits set)
	Or specify a CIDR prefix size (0 to 32)
	Use this in an office with multiple subnets that can all be covered (summarised) by a single netmask.
	Without this parameter the default is to use the subnet mask of the local machine interface(s), if localSubnetOnly is on.
.PARAMETER emailTo
	Address to be notified about success and problems. If not given no Emails will be sent.
.PARAMETER emailFrom
	Address the notification email is sent from. If not given no Emails will be sent.
.PARAMETER SMTPServer
	Domainname of the SMTP Server. If not given no Emails will be sent.
.PARAMETER SMTPUser
	Username if the SMTP Server needs authentication.
.PARAMETER SMTPPassword
	Password if the SMTP Server needs authentication.
.PARAMETER SMTPTimeout
	Timeout in ms for the Email to be sent. Default 60000.
.PARAMETER NoSMTPOverSSL
	Switch off the use of SSL to send Emails.
.PARAMETER NoShadowCopy
	Switch off the use of Shadow Copies. Can be useful if you have no permissions to create Shadow Copies.
.PARAMETER SMTPPort
	Port of the SMTP Server. Default=587
.PARAMETER emailJobName
	This is added in to the auto-generated email subject "Backup of: hostname emailJobName by: username"
.PARAMETER emailSubject
	Subject for the notification Email. This overrides the auto-generated email subject and emailJobName.
.PARAMETER emailSendRetries
	How many times should we try to resend the Email. Default = 100
.PARAMETER msToPauseBetweenEmailSendRetries
	Time in ms to wait between the resending of the Email. Default = 60000
.PARAMETER LogFile
	Path and filename for the logfile. If just a path is given, then "yyyy-mm-dd hh-mm-ss.log" is written to that folder.
	Default is to write "yyyy-mm-dd hh-mm-ss.log" in the backup destination folder.
.PARAMETER StepTiming
	Switch on display of the time at each step of the job.
.PARAMETER preExecutionCommand
	Command to run before the start of the backup.
.PARAMETER preExecutionDelay
	Time in milliseconds to pause between running the preExecutionCommand and the start of the backup. Default = 0
.PARAMETER postExecutionCommand
	Command to run after the backup is done.
.PARAMETER lnPath
	The full path to the ln executable. e.g. c:\Tools\Backup\ln.exe
.PARAMETER unroll
	Unroll follows Outer Junctions/Symlink Directories and rebuilds the content of Outer Junctions/Symlink Directories inside the hierarchy at the destination location.
	Unroll also applies to Outer Symlink Files, which means, that unroll causes the target of Outer Symlink Files to be copied to the destination location.
	see http://schinagl.priv.at/nt/ln/ln.html#unroll
.PARAMETER LogVerbose
	Increase verbosity of messages on the logfile.
.PARAMETER EchoVerbose
	Increase verbosity of messages on the screen.
.PARAMETER SkipIfNoChanges
	Check log file for changes on source and delete backup folder if not changes.
	Thus, we get less backup folders and therefore less hard links. Delaying the possibility of reaching the NTFS link limit of 1023.
.PARAMETER ClosestRotation
	Strategy of snapshot rotation keeping the most closest and the first backup in a time period.
	Other strategies such backupsToKeep and backupsToKeepPerYear will be accumulated.
	If you want to disable some of these, set them to 1.
.PARAMETER FullBackup
	Make a full backup
.PARAMETER FullBackupEvery
	Make a full backup (--copy parameter of ln.exe tool) each 'FullBackupEvery' backup(s)
.PARAMETER UseDriveName
	Add Drive Name To Source Folder Destination
	Thus, if you have source folder with the same name, have not conflicts!
.PARAMETER DryRun
	Simulation Mode. Do not delete backup folders, only show results
	of Backup Strategy.
.PARAMETER version
	print the version information and exit.	
.EXAMPLE
	PS D:\> d:\ln\bat\ntfs-hardlink-backup.ps1 -backupSources D:\backup_source1 -backupDestination E:\backup_dest -emailTo "me@example.org" -emailFrom "backup@example.org" -SMTPServer example.org -SMTPUser "backup@example.org" -SMTPPassword "secr4et"
	Simple backup.
.EXAMPLE
	PS D:\> d:\ln\bat\ntfs-hardlink-backup.ps1 -backupSources "D:\backup_source1","C:\backup_source2" -backupDestination E:\backup_dest -emailTo "me@example.org" -emailFrom "backup@example.org" -SMTPServer example.org -SMTPUser "backup@example.org" -SMTPPassword "secr4et"
	Backup with more than one source.
.NOTES
	Author: Artur Neumann *INFN*, Phil Davis *INFN*, Nikita Feodonit
.BACKWARDS COMPATIBILITY
	Now $lastBackupFolders have only the names and not the items
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False)]
	[String]$iniFile,
	[Parameter(Mandatory=$False)]
	[String[]]$backupSources,
	[Parameter(Mandatory=$False)]
	[String[]]$backupDestination,
	[Parameter(Mandatory=$False)]
	[String]$subst,
	[Parameter(Mandatory=$False)]
	[Int32]$backupsToKeep,
	[Parameter(Mandatory=$False)]
	[Int32]$backupsToKeepPerYear,
	[Parameter(Mandatory=$False)]
	[string]$emailTo="",
	[Parameter(Mandatory=$False)]
	[string]$emailFrom="",
	[Parameter(Mandatory=$False)]
	[string]$SMTPServer="",
	[Parameter(Mandatory=$False)]
	[string]$SMTPUser="",
	[Parameter(Mandatory=$False)]
	[string]$SMTPPassword="",
	[Parameter(Mandatory=$False)]
	[switch]$NoSMTPOverSSL=$False,
	[Parameter(Mandatory=$False)]
	[switch]$NoShadowCopy=$False,
	[Parameter(Mandatory=$False)]
	[Int32]$SMTPPort,
	[Parameter(Mandatory=$False)]
	[Int32]$SMTPTimeout,
	[Parameter(Mandatory=$False)]
	[Int32]$emailSendRetries,
	[Parameter(Mandatory=$False)]
	[Int32]$msToPauseBetweenEmailSendRetries,
	[Parameter(Mandatory=$False)]
	[Int32]$timeTolerance,
	[Parameter(Mandatory=$False)]
	[switch]$traditional,
	[Parameter(Mandatory=$False)]
	[switch]$noads,
	[Parameter(Mandatory=$False)]
	[switch]$noea,
	[Parameter(Mandatory=$False)]
	[switch]$splice,
	[Parameter(Mandatory=$False)]
	[switch]$backupModeACLs,
	[Parameter(Mandatory=$False)]
	[switch]$localSubnetOnly,
	[Parameter(Mandatory=$False)]
	[string]$localSubnetMask,
	[Parameter(Mandatory=$False)]
	[string]$emailSubject="",
	[Parameter(Mandatory=$False)]
	[string]$emailJobName="",
	[Parameter(Mandatory=$False)]
	[String[]]$excludeFiles,
	[Parameter(Mandatory=$False)]
	[String[]]$excludeDirs,
	[Parameter(Mandatory=$False)]
	[string]$LogFile="",
	[Parameter(Mandatory=$False)]
	[switch]$StepTiming=$False,
	[Parameter(Mandatory=$False)]
	[string]$preExecutionCommand="",
	[Parameter(Mandatory=$False)]
	[Int32]$preExecutionDelay,
	[Parameter(Mandatory=$False)]
	[string]$postExecutionCommand="",
	[Parameter(Mandatory=$False)]
	[string]$lnPath="",
	[Parameter(Mandatory=$False)]
	[switch]$unroll,
	[Parameter(Mandatory=$False)]
	[switch]$LogVerbose=$False,
	[Parameter(Mandatory=$False)]
	[switch]$EchoVerbose=$False,
	[Parameter(Mandatory=$False)]
	[switch]$SkipIfNoChanges,
	[Parameter(Mandatory=$False)]
	[switch]$ClosestRotation,
	[Parameter(Mandatory=$False)]
	[switch]$FullBackup,
	[Parameter(Mandatory=$False)]
	[string]$FullBackupEvery,
	[Parameter(Mandatory=$False)]
	[switch]$UseDriveName,
	[Parameter(Mandatory=$False)]
	[switch]$DryRun=$False,
	[Parameter(Mandatory=$False)]
	[switch]$version=$False
)
Set-StrictMode -version Latest
#The path and filename of the script it self
$script_path = Split-Path -parent $MyInvocation.MyCommand.Definition

#Initialize variables
if (!(test-path variable:\included_inf_functions)) {$included_inf_functions = $False} # test for EXISTENCE & create
if (!(test-path variable:\included_functions)) {$included_functions = $False} # test for EXISTENCE & create
if (!(test-path variable:\included_features)) {$included_features = $False} # test for EXISTENCE & create

#----- Include Files -----#
if(!$included_inf_functions)
{
	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
	. (Join-Path $ScriptDirectory inf-functions.ps1)
}

if(!$included_functions)
{
	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
	. (Join-Path $ScriptDirectory functions.ps1)
}

if(!$included_features)
{
	$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
	. (Join-Path $ScriptDirectory features.ps1)
}

Function Get-Version
{
<#
	.Synopsis
		Gets the version of this script

	.Description
		Parses the description for a line that looks like:
		NTFS-HARDLINK-BACKUP Version: 2.0.ALPHA.8
		and gets the version information out of it
		The version string must be in the .DESCRIPTION scope and must start with
		"NTFS-HARDLINK-BACKUP Version: "

	.Outputs
		System.String
	#>
	
	#Get the help-text of my self
	$helpText=Get-Help $script_path/ntfs-hardlink-backup.ps1 
	
	#Get-Help returns a PSObjects with other PSObjects inside
	#So we are trying some black magic to get a string out of it and then to parse the version
	
	Foreach ($object in $helpText.psobject.properties) { 
		#loop through all properties of the PSObject and find the description
		if (($object.Value) -and  ($object.name -eq "description")) {
			#the description is a object of the class System.Management.Automation.PSNoteProperty
			#and inside of the properties of that are System.Management.Automation.PSPropertyInfo objects (in our case only one)
			#still we loop though, just in case there are more that one and see if the value (what is finally a string), does match the version string
			Foreach ($subObject in $object.Value[0].psobject.properties) { 	
				 if ($subObject.Value -match "NTFS-HARDLINK-BACKUP Version: (.*)")	{
						return $matches[1]
				} 
			} 
		}
	}
}

$emailBody = ""
$error_during_backup = $false
$doBackup = $true
$maxMsToSleepForZipCreation = 1000*60*30
$msToWaitDuringZipCreation = 500
$shadow_drive_letter = ""
$num_shadow_copies = 0
$stepTime = ""
$backupMappedPath = ""
$backupHostName = ""
$deleteOldLogFiles = $False
$FQDN = [System.Net.DNS]::GetHostByName('').HostName
$userName = [Environment]::UserName
$tempLogContent = ""
$substDone = $False

$versionString=Get-Version

if ($version) {
	Write-Host $versionString
	exit
} else {
	$output = "NTFS-HARDLINK-BACKUP $versionString`r`n"
	$emailBody = "$emailBody`r`n$output`r`n"
	$tempLogContent += "$output`r`n"
	Write-Host $output
}

if ($iniFile) {
	if (Test-Path -Path $iniFile -PathType leaf) {
		$output = "Using ini file`r`n$iniFile`r`n"
		$global:iniFileContent = Get-IniContent "${iniFile}"
	} else {
		$global:iniFileContent =  New-Object System.Collections.Specialized.OrderedDictionary
		$output = "ERROR: Could not find ini file`r`n$iniFile`r`n"
	}

	$emailBody = "$emailBody`r`n$output`r`n"
	Write-Host $output
	$tempLogContent += "$output`r`n"
} else {
		$global:iniFileContent =  New-Object System.Collections.Specialized.OrderedDictionary
}

$parameters_ok = $True

if ([string]::IsNullOrEmpty($backupSources)) {
	$backupsourcelist = Get-IniParameter "backupsources" "${FQDN}"
	if (-not [string]::IsNullOrEmpty($backupsourcelist)) {
		$backupSources = $backupsourcelist.split(",")
	}
}

if ([string]::IsNullOrEmpty($backupDestination)) {
	$backupDestinationList = Get-IniParameter "backupdestination" "${FQDN}"

	if (-not [string]::IsNullOrEmpty($backupDestinationList)) {
		$backupDestination = $backupDestinationList.split(",")
	}	
}

if ([string]::IsNullOrEmpty($subst)) {
	$subst = Get-IniParameter "subst" "${FQDN}"
}

# This is always a drive-like letter, so it looks usual in Windows to be upper-case
$subst = $subst.toupper()

if ($backupsToKeep -eq 0) {
	$backupsToKeep = Get-IniParameter "backupstokeep" "${FQDN}"
	if ($backupsToKeep -eq 0) {
		$backupsToKeep = 50;
	}
}
#PARAMETER backupsToKeep applied to logFiles
$logFilesToKeep=$backupsToKeep

if ($backupsToKeepPerYear -eq 0) {
	$backupsToKeepPerYear = Get-IniParameter "backupsToKeepPerYear" "${FQDN}"
	if ($backupsToKeepPerYear -eq 0) {
		$backupsToKeepPerYear = 0;
	}
}

if ([string]::IsNullOrEmpty($emailTo)) {
	$emailTo = Get-IniParameter "emailTo" "${FQDN}"
}

if ([string]::IsNullOrEmpty($emailFrom)) {
	$emailFrom = Get-IniParameter "emailFrom" "${FQDN}"
}

if ([string]::IsNullOrEmpty($SMTPServer)) {
	$SMTPServer = Get-IniParameter "SMTPServer" "${FQDN}"
}

if ([string]::IsNullOrEmpty($SMTPUser)) {
	$SMTPUser = Get-IniParameter "SMTPUser" "${FQDN}"
}

if ([string]::IsNullOrEmpty($SMTPPassword)) {
	$SMTPPassword = Get-IniParameter "SMTPPassword" "${FQDN}" -doNotSubstitute
}

if (-not $NoSMTPOverSSL.IsPresent) {
	$IniFileString = Get-IniParameter "NoSMTPOverSSL" "${FQDN}"
	$NoSMTPOverSSL = Is-TrueString "${IniFileString}"
}

if (-not $NoShadowCopy.IsPresent) {
	$IniFileString = Get-IniParameter "NoShadowCopy" "${FQDN}"
	$NoShadowCopy = Is-TrueString "${IniFileString}"
}

if ($SMTPPort -eq 0) {
	$SMTPPort = Get-IniParameter "SMTPPort" "${FQDN}"
	if ($SMTPPort -eq 0) {
		$SMTPPort = 587;
	}
}

if ($SMTPTimeout -eq 0) {
	$SMTPTimeout = Get-IniParameter "SMTPTimeout" "${FQDN}"
	if ($SMTPTimeout -eq 0) {
		$SMTPTimeout = 60000;
	}
}

if ($emailSendRetries -eq 0) {
	$emailSendRetries = Get-IniParameter "emailSendRetries" "${FQDN}"
	if ($emailSendRetries -eq 0) {
		$emailSendRetries = 100;
	}
}

if ($msToPauseBetweenEmailSendRetries -eq 0) {
	$msToPauseBetweenEmailSendRetries = Get-IniParameter "msToPauseBetweenEmailSendRetries" "${FQDN}"
	if ($msToPauseBetweenEmailSendRetries -eq 0) {
		$msToPauseBetweenEmailSendRetries = 60000;
	}
}

if ($timeTolerance -eq 0) {
	$timeTolerance = Get-IniParameter "timeTolerance" "${FQDN}"
	if ($timeTolerance -eq 0) {
		# Looks dumb, but left here if you want to change the default from zero.
		$timeTolerance = 0;
	}
}

if (-not $traditional.IsPresent) {
	$IniFileString = Get-IniParameter "traditional" "${FQDN}"
	$traditional = Is-TrueString "${IniFileString}"
}

if (-not $noads.IsPresent) {
	$IniFileString = Get-IniParameter "noads" "${FQDN}"
	$noads = Is-TrueString "${IniFileString}"
}

if (-not $noea.IsPresent) {
	$IniFileString = Get-IniParameter "noea" "${FQDN}"
	$noea = Is-TrueString "${IniFileString}"
}

if (-not $splice.IsPresent) {
	$IniFileString = Get-IniParameter "splice" "${FQDN}"
	$splice = Is-TrueString "${IniFileString}"
}

if (-not $backupModeACLs.IsPresent) {
	$IniFileString = Get-IniParameter "backupModeACLs" "${FQDN}"
	$backupModeACLs = Is-TrueString "${IniFileString}"
}

if (-not $localSubnetOnly.IsPresent) {
	$IniFileString = Get-IniParameter "localSubnetOnly" "${FQDN}"
	$localSubnetOnly = Is-TrueString "${IniFileString}"
}

if ([string]::IsNullOrEmpty($localSubnetMask)) {
	$localSubnetMask = Get-IniParameter "localSubnetMask" "${FQDN}"
}

if (![string]::IsNullOrEmpty($localSubnetMask)) {
	$CIDRbitCount = 0
	# Check if we have an integer
	if ([int]::TryParse($localSubnetMask, [ref]$CIDRbitCount)) {
		# That is also in the range 0 to 32
		if (($CIDRbitCount -ge 0) -and ($CIDRbitCount -le 32)) {
			# And turn it into a 255.255.255.0 style string
			$CIDRremainder = $CIDRbitCount % 8
			$CIDReights = [Math]::Floor($CIDRbitCount / 8)
			switch ($CIDRremainder) {
				0 { $CIDRbitText = "0" }
				1 { $CIDRbitText = "128" }
				2 { $CIDRbitText = "192" }
				3 { $CIDRbitText = "224" }
				4 { $CIDRbitText = "240" }
				5 { $CIDRbitText = "248" }
				6 { $CIDRbitText = "252" }
				7 { $CIDRbitText = "254" }
			}
			switch ($CIDReights) {
				0 { $localSubnetMask = $CIDRbitText + ".0.0.0" }
				1 { $localSubnetMask = "255." + $CIDRbitText + ".0.0" }
				2 { $localSubnetMask = "255.255." + $CIDRbitText + ".0" }
				3 { $localSubnetMask = "255.255.255." + $CIDRbitText }
				4 { $localSubnetMask = "255.255.255.255" }
			}
		}
	}
	$validNetMaskNumbers = '0|128|192|224|240|248|252|254|255'
	$netMaskRegexArray = @(
		"(^($validNetMaskNumbers)\.0\.0\.0$)"
		"(^255\.($validNetMaskNumbers)\.0\.0$)"
		"(^255\.255\.($validNetMaskNumbers)\.0$)"
		"(^255\.255\.255\.($validNetMaskNumbers)$)"
	)
	$netMaskRegex = [string]::Join('|', $netMaskRegexArray)
	
	if (!(($localSubnetMask -Match $netMaskRegex))) {
		# The string is not a valid network mask.
		# It should be something like 255.255.255.0
		$output = "`nERROR: localSubnetMask $localSubnetMask is not valid`n"
		Write-Host $output
		$emailBody = "$emailBody`r`n$output`r`n"

		$tempLogContent += $output

		$parameters_ok = $False
		$localSubnetMask = ""
	}
}

if ([string]::IsNullOrEmpty($emailSubject)) {
	$emailSubject = Get-IniParameter "emailSubject" "${FQDN}"
}

if ([string]::IsNullOrEmpty($emailJobName)) {
	$emailJobName = Get-IniParameter "emailJobName" "${FQDN}"
}

if ([string]::IsNullOrEmpty($excludeFiles)) {
	$excludeFilesList = Get-IniParameter "excludeFiles" "${FQDN}"
	if (-not [string]::IsNullOrEmpty($excludeFilesList)) {
		$excludeFiles = $excludeFilesList.split(",")
	}
}

if ([string]::IsNullOrEmpty($excludeDirs)) {
	$excludeDirsList = Get-IniParameter "excludeDirs" "${FQDN}"
	if (-not [string]::IsNullOrEmpty($excludeDirsList)) {
		$excludeDirs = $excludeDirsList.split(",")
	}
}

if (-not $StepTiming.IsPresent) {
	$IniFileString = Get-IniParameter "StepTiming" "${FQDN}"
	$StepTiming = Is-TrueString "${IniFileString}"
}

if ([string]::IsNullOrEmpty($emailSubject)) {
	if (-not ([string]::IsNullOrEmpty($emailJobName))) {
		$emailJobName += " "
	}
	$emailSubject = "Backup of: ${FQDN} ${emailJobName}by: ${userName}"
}

if ([string]::IsNullOrEmpty($preExecutionCommand)) {
	$preExecutionCommand = Get-IniParameter "preExecutionCommand" "${FQDN}" -doNotSubstitute
}	

if (![string]::IsNullOrEmpty($preExecutionCommand)) {
	$output = "`nrunning preexecution command ($preExecutionCommand)`n"	
	$output += `cmd /c  `"$preExecutionCommand`" 2`>`&1`
	
	#if the command fails we want a message in the Email, otherwise the details will be only shown in the log file
	#make sure this if statement is directly after the cmd command
	if(!$?) {
		$output += "`n`nERROR: the pre-execution-command ended with an error" 
		$emailBody = "$emailBody`r$output`r`n"
		$error_during_backup = $True
	}
	
	$output += "`n"
	Write-Host $output
	$tempLogContent += $output
	}
	
if ($preExecutionDelay -eq 0) {
	$preExecutionDelay = Get-IniParameter "preExecutionDelay" "${FQDN}"
	if ($preExecutionDelay -eq 0) {
		# Looks dumb, but left here if you want to change the default from zero.
		$preExecutionDelay = 0;
	}
}

if ($preExecutionDelay -gt 0) {
	Write-Host "I'm gona be lazy now"

	Write-Host -NoNewline "

         ___    z
       _/   |  z
      |_____|{)_
        --- ==\/\ |
      [_____]  __)|
      |   |  //| |
	"
	$CursorTop=[Console]::CursorTop
	[Console]::SetCursorPosition(18,$CursorTop-7)
	for ($msSleeped=0;$msSleeped -lt $preExecutionDelay; $msSleeped+=1000){
		Start-sleep -milliseconds 1000
		Write-Host -NoNewline "z "
	}	
	[Console]::SetCursorPosition(0,$CursorTop)
	Write-Host "I guess it's time to wake up.`n"
}

if ([string]::IsNullOrEmpty($postExecutionCommand)) {
	$postExecutionCommand = Get-IniParameter "postExecutionCommand" "${FQDN}" -doNotSubstitute
}

#Unroll parameter
if (-not $unroll.IsPresent) {
	$IniFileString = Get-IniParameter "unroll" "${FQDN}"
	$unroll = Is-TrueString "${IniFileString}"
}

#LogVerbose parameter
if (-not $LogVerbose.IsPresent) {
	$IniFileString = Get-IniParameter "LogVerbose" "${FQDN}"
	$LogVerbose = Is-TrueString "${IniFileString}"
}

#EchoVerbose parameter
if (-not $EchoVerbose.IsPresent) {
	$IniFileString = Get-IniParameter "EchoVerbose" "${FQDN}"
	$EchoVerbose = Is-TrueString "${IniFileString}"
}

#SkipIfNoChanges parameter
if (-not $SkipIfNoChanges.IsPresent) {
	$IniFileString = Get-IniParameter "SkipIfNoChanges" "${FQDN}"
	$SkipIfNoChanges = Is-TrueString "${IniFileString}"
}

#ClosestRotation parameter
if (-not $ClosestRotation.IsPresent) {
	$IniFileString = Get-IniParameter "ClosestRotation" "ClosestRotation"
	if(!$IniFileString){ $IniFileString = Get-IniParameter "ClosestRotation" "${FQDN}" }
	$ClosestRotation = Is-TrueString "${IniFileString}"
}

#FullBackup parameter
if (-not $FullBackup.IsPresent) {
	$IniFileString = Get-IniParameter "FullBackup" "${FQDN}"
	$FullBackup = Is-TrueString "${IniFileString}"
}

#FullBackupEvery parameter
# Preference: Given Parameter Value on Command Line, Parameter on Ini File, 0
$FullBackupEveryConfig = @(Get-IniArray "FullBackupEvery" "${FQDN}" @(0))
if($FullBackupEvery)
{
	$FullBackupEveryConfig = @(ArrayOverwrite $FullBackupEveryConfig @($FullBackupEvery -split ","))
}
if([int]$FullBackupEveryConfig[0] -gt 0)
{
		# Have no counter, add FullBackupEvery Value as Counter
	if($FullBackupEveryConfig.length -eq 1)
	{ 
		$FullBackupEveryConfig+=$FullBackupEveryConfig 
	}
	
		# If counter gets 0, do a full backup (Or passed Parameter FullBackup=$True)
	if($FullBackup  -or ([int]$FullBackupEveryConfig[1] -eq 0))
	{
		$FullBackupEveryConfig[1]=[int]$FullBackupEveryConfig[0]	# Reset counter
		
		If($FullBackup)
		{
			Verbose "Making a Full Backup (FullBackup Parameter On)`n"
		}
		else
		{
			Verbose "Making a Full Backup (FullBackupEvery=$($FullBackupEveryConfig[0]))`nThis is the backup number $($FullBackupEveryConfig[0]) from the last Full Backup`n"
			$FullBackup=$True
		}		
	}
	else
	{
		$FullBackupEveryConfig[1]=[int]$FullBackupEveryConfig[1]-1	# Decrease counter
		if([int]$FullBackupEveryConfig[1] -gt 0)
		{
			Verbose "$($FullBackupEveryConfig[1]) backup(s) left for one Full Backup (FullBackupEvery=$($FullBackupEveryConfig[0]))`n"
		}
		else
		{
			Verbose "Next backup will be Full Backup (FullBackupEvery=$($FullBackupEveryConfig[0]))`n"
		}
	}

		# Write new counter values to ini file
	Set-IniValue $iniFile "FullBackupEvery" ($FullBackupEveryConfig -join ",")
}
elseif($FullBackup)
{
	Verbose "Making a Full Backup (FullBackup Parameter On)`n"
}

#UseDriveName parameter
if (-not $UseDriveName.IsPresent) {
	$IniFileString = Get-IniParameter "UseDriveName" "${FQDN}"
	$UseDriveName = Is-TrueString "${IniFileString}"
}

#DryRun parameter
if (-not $DryRun.IsPresent) {
	$IniFileString = Get-IniParameter "DryRun" "${FQDN}"
	$DryRun = Is-TrueString "${IniFileString}"
}

if ([string]::IsNullOrEmpty($lnPath)) {
	$lnPath = Get-IniParameter "lnPath" "${FQDN}"
}

#if lnPath is not given in the ini file nor on the command line or its not there try to find it somewhere else
if ([string]::IsNullOrEmpty($lnPath) -or !(Test-Path -Path $lnPath -PathType leaf)  ) {
	if (Test-Path -Path "$script_path\ln.exe" -PathType leaf) {
		$lnPath="$script_path\ln.exe"
	} elseif (Test-Path -Path "$script_path\..\ln.exe" -PathType leaf) {
		$lnPath="$script_path\..\ln.exe"
	} else {
		#last chance, somewhere in the PATH Environment variable
		foreach ($ENVpath in $env:path.split(";")) {	
			if (Test-Path -Path "$ENVpath\ln.exe" -PathType leaf) {
				$lnPath="$ENVpath\ln.exe"
				break;
			}
		}
	}
}

if($DryRun -eq $True)
{
	$echo="`nSimulation Mode: No backup folder(s) will be damaged :)"
	$tempLogContent+="`r`n$echo`r`n`r`n"
	Write-Host "`n$echo`n"
}

#Verbose. Showing ln.exe path 
$echo="Using ln.exe from: $lnPath`n"
if($LogVerbose) {$tempLogContent += "$echo"}
if($EchoVerbose) {Write-Host "$echo"}

#try to run ln.exe just to check if it can start. Possible that the ln version does not fit the Windows version (e.g. 64bit installed on a 32bit system)
$output=`cmd /c "`"$lnPath`"  -h" 2`>`&1`

#if we could not find ln.exe, there is no point in trying to make a backup
if ([string]::IsNullOrEmpty($lnPath) -or !(Test-Path -Path $lnPath -PathType leaf) -or ($LASTEXITCODE -ne 0) ) {
	$output += "`nERROR: could not run ln.exe`n"
	Write-Host $output
	$emailBody = "$emailBody`r`n$output`r`n"
	
	$tempLogContent += $output
	
	$parameters_ok = $False
}

$dateTime = get-date -f "yyyy-MM-dd HH-mm-ss"

if ([string]::IsNullOrEmpty($backupDestination)) {
	# No backup destination on command line or in INI file
	# backup destination is mandatory, so flag the problem.
	$output = "`nERROR: No backup destination specified`n"
	Write-Host $output
	$emailBody = "$emailBody`r`n$output`r`n"
	
	$tempLogContent += $output
	
	$parameters_ok = $False
} else {
	foreach ($possibleBackupDestination in $backupDestination) {
		# Initialize vars used in this loop to ensure they do not end up with values from previous loop iterations.
		$backupDestinationTop = ""
		$backupMappedPath = ""
		$backupHostName = ""

		# If the user wants to substitute a drive letter for the backup destination, do that now.
		# Then following code can process the resulting "subst" in the same way as if the user had done it externally.
		if (-not ([string]::IsNullOrEmpty($subst))) {
			if ($subst -match "^[A-Z]:?$") { #TODO add check if we try to subst a not UNC path
				$substDrive = $subst.Substring(0,1) + ":"
				# Delete any previous or externally-defined subst-ed drive on this letter.
				# Send the output to null, as usually the first attempted delete will give an error, and we do not care.
				$substDone = $False
				subst "$substDrive" /d | Out-Null
				try {
					if (!(Test-Path -Path $possibleBackupDestination)) {
						New-Item $possibleBackupDestination -type directory -ea stop | Out-Null
					}
					subst "$substDrive" $possibleBackupDestination
					$possibleBackupDestination = $substDrive					
					$substDone = $True
				}
				catch {
					$output = "`nERROR: Destination was not found and could not be created. $_`n"
					Write-Host $output
					$emailBody = "$emailBody`r`n$output`r`n"
					
					$tempLogContent += $output
				}
				
			} else {
				$output = "`nERROR: subst parameter $subst is invalid`n"
				Write-Host $output
				$emailBody = "$emailBody`r`n$output`r`n"
				
				$tempLogContent += $output
				
				# Flag that there is a problem, but let following code process and report any other problems before bailing out.
				$parameters_ok = $False
			}
		}
		
		# Process the backup destination to find out where it might be
		$backupDestinationArray = $possibleBackupDestination.split("\")

		if (($backupDestinationArray[0] -eq "") -and ($backupDestinationArray[1] -eq "")) {
			# The destination is a UNC path (file share)
			$backupDestinationTop = "\\" + $backupDestinationArray[2] + "\" + $backupDestinationArray[3] + "\"
			$backupMappedPath = $backupDestinationTop
			$backupHostName = $backupDestinationArray[2]
		} else {
			if (-not ($possibleBackupDestination -match ":")) {
				# No drive letter specified. This could be an attempt at a relative path, so first resolve it to the full path.
				# This allows us to use split-path -Qualifier below to get the actual drive letter
				$possibleBackupDestination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($possibleBackupDestination)
			}
			$backupDestinationDrive = split-path $possibleBackupDestination -Qualifier
			# toupper the backupDestinationDrive string to help findstr below match the upper-case output of subst. 
			# Also seems a reasonable thing to do in Windows, since drive letters are usually displayed in upper-case.
			$backupDestinationDrive = $backupDestinationDrive.toupper()
			$backupDestinationTop = $backupDestinationDrive + "\"
			# See if the disk letter is mapped to a file share somewhere.
			$backupDriveObject = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$backupDestinationDrive'"
			$backupMappedPath = $backupDriveObject.ProviderName
			if ($backupMappedPath) {
				$backupPathArray = $backupMappedPath.split("\")
				if (($backupPathArray[0] -eq "") -and ($backupPathArray[1] -eq "")) {
					# The underlying destination is a UNC path (file share)
					$backupHostName = $backupPathArray[2]
				}
			} else {
				# Maybe the user did a "subst" command. Check for that.
				$substText = (Subst) | findstr "$backupDestinationDrive\\"
				# Looks like one of:
				# R:\: => UNC\hostname.myoffice.company.org\sharename
				# R:\: => C:\some\folder\path
				# If a subst exists, it should always split into 3 space-separated parts
				$parts = $substText -Split " "
				if (($parts[0]) -and ($parts[1]) -and ($parts[2])) {
					$backupMappedPath = $parts[2]
					if ($backupMappedPath -match "^UNC\\") {
						$host_FQDN = $backupMappedPath.split("\")[1]
						$backupMappedPath = "\" + $backupMappedPath.Substring(3)
						if ($host_FQDN) {
							$backupHostName = $host_FQDN
						}
					}
				}
			}
		}

		if ($backupMappedPath) {
			$backupMappedString = " (" + $backupMappedPath + ")"
		} else {
			$backupMappedString = ""
		}

		if (($localSubnetOnly -eq $True) -and ($backupHostName)) {
			# Check that the name is in the same subnet as us.
			# Note: This also works if the user gives a real IPv4 like "\\10.20.30.40\backupshare"
			# $backupHostName would be 10.20.30.40 in that case.
			# TODO: Handle IPv6 addresses also some day.
			$doBackup = $false
			try {
				$destinationIpAddresses = [System.Net.Dns]::GetHostAddresses($backupHostName)
				[IPAddress]$destinationIp = $destinationIpAddresses[0]

				$localAdapters = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"')

				foreach ($adapter in $localAdapters) {
					# Belts and braces here - we have seen some systems that returned unusual adapters that had IPaddress 0.0.0.0 and no IPsubnet
					# We want to ignore that sort of rubbish - the mask comparisons do not work.
					if ($adapter.IPAddress[0]) {
						[IPAddress]$IPv4Address = $adapter.IPAddress[0]
						if ($adapter.IPSubnet[0]) {
							if ([string]::IsNullOrEmpty($localSubnetMask)) {
								[IPAddress]$mask = $adapter.IPSubnet[0]
							} else {
								[IPAddress]$mask = $localSubnetMask
							}

							if (($IPv4address.address -band $mask.address) -eq ($destinationIp.address -band $mask.address)) {
								$doBackup = $true
							}
						}
					}
				}
			}
			catch {
				$output = "ERROR: Could not get IP address for destination $possibleBackupDestination mapped to $backupMappedPath"
				$emailBody = "$emailBody`r`n$output`r`n$_"
				$error_during_backup = $true
				Write-Host $output  $_
			}
		}

		if (($parameters_ok -eq $True) -and ($doBackup -eq $True) -and (test-path $backupDestinationTop)) {
				$selectedBackupDestination = $possibleBackupDestination
				break
		}	
	}
}

if ([string]::IsNullOrEmpty($LogFile)) {
	$LogFile = Get-IniParameter "LogFile" "${FQDN}"
}

if ([string]::IsNullOrEmpty($LogFile)) {
	# No log file specified from command line - put one in the backup destination with date-time stamp.
	$logFileDestination = $selectedBackupDestination
	if ($logFileDestination) {
		$LogFile = "$logFileDestination\$dateTime.log"
	} else {
		# This can happen if both the logfile and backup destination parameters were not in the INI file and not on the command line.
		# In this case no log file is made. But we do proceed so there will be an email body and the receiver can find out what is wrong.
		$LogFile = ""
	}
	$deleteOldLogFiles = $True
} else {
	if (Test-Path -Path $LogFile -pathType container) {
		# The log file parameter points to a folder, so generate log file names in that folder.
		$logFileDestination = $LogFile
		$LogFile = "$logFileDestination\$dateTime.log"
		$deleteOldLogFiles = $True
	} else {
		# The log file name has been fully specified - just calculate the parent folder.
		$logFileDestination = Split-Path -parent $LogFile
	}
}

try
{
	New-Item "$LogFile" -type file -force -erroraction stop | Out-Null
}
catch
{
	$output = "ERROR: Could not create new log file`r`n$_`r`n"
	$emailBody = "$emailBody`r`n$output`r`n"
	Write-Host $output
	$LogFile=""
	$error_during_backup = $True
	$deleteOldLogFiles = $False
}

#write the logs from the time we hadn't a logfile into the file
WriteLog $tempLogContent

if ([string]::IsNullOrEmpty($backupSources)) {
	# No backup sources on command line, in host-specific or common section of ini file
	# backup sources are mandatory, so flag the problem.
	$output = "`nERROR: No backup source(s) specified`n"
	Write-Host $output
	$emailBody = "$emailBody`r`n$output`r`n"
	WriteLog $output
	$parameters_ok = $False
}

# Just test for the existence of the top of the backup destination. "ln" will create any folders as needed, as long as the top exists.
if (($parameters_ok -eq $True) -and ($doBackup -eq $True) -and (test-path $backupDestinationTop)) {
	foreach ($backup_source in $backupSources)
	{
		# Restart Stepcounter to 1
		StepCounter -counter 1
		
		#We don't want to have "\" at the end because we will quote the path later and ln.exe would 
		#treat this as escaping of the quote (\") and can not parse the command line.
		#ln --copy "x:\" y:\dir\newdir 
		#see also https://github.com/individual-it/ntfs-hardlink-backup/issues/16
		if ($backup_source.substring($backup_source.length-1,1) -eq "\") {
			$backup_source=$backup_source.Substring(0,$backup_source.Length-1)
		}

		if (test-path -LiteralPath $backup_source) {
			$backupSourceArray = $backup_source.split("\")
			if (($backupSourceArray[0] -eq "") -and ($backupSourceArray[1] -eq "")) {
				# The source is a UNC path (file share) which has no drive letter. We cannot do volume shadowing from that.
				$backup_source_drive_letter = ""
				$backup_source_path = ""
			} else {
				if (-not ($backup_source -match ":")) {
					# No drive letter specified. This could be an attempt at a relative path, so first resolve it to the full path.
					# This allows us to use split-path -Qualifier below to get the actual drive letter
					$backup_source = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($backup_source)
				}
				$backup_source_drive_letter = split-path $backup_source -Qualifier
				$backup_source_path =  split-path $backup_source -noQualifier
			}
			
			#check if we try to backup a complete drive
			if (($backup_source_drive_letter -ne "") -and ($backup_source_path -eq "")) {
				if ($backup_source_drive_letter -match "([A-Z]):") {
					$backup_source_folder = "["+$matches[1]+"]"
				}
			} else {
				$backup_source_folder =  split-path $backup_source -leaf
				if($UseDriveName -and ($backup_source_drive_letter -match "([A-Z]):") )
				{
					$backup_source_folder=$matches[1]+"_"+$backup_source_folder
				}
			}
			
			$actualBackupDestination = "$selectedBackupDestination\$backup_source_folder"

			#if the user wants to keep just one backup we do a mirror without any date, so we don't need
			#to copy files that are already there
			if ($backupsToKeep -gt 1) {
				$actualBackupDestination = "$actualBackupDestination - $dateTime"
			}

			$echo="============Creating Backup of $backup_source============"
			Write-Host $echo
			WriteLog "$echo"
			
			if ($NoShadowCopy -eq $False) {
				if ($backup_source_drive_letter -ne "") {
				# We can try processing a shadow copy.
					if ($shadow_drive_letter -eq $backup_source_drive_letter) {
						# The previous shadow copy must have succeeded because $NoShadowCopy is still false, and we are looping around with a matching shadow drive letter.
						
						StepCounter "Re-using previous Shadow Volume Copy"
						$backup_source_path = $s2.DeviceObject+$backup_source_path
					} else {
						if ($num_shadow_copies -gt 0) {
							# Delete the previous shadow copy that was from some other drive letter
							foreach ($shadowCopy in $shadowCopies) {
								if ($s2.ID -eq $shadowCopy.ID) {
									StepCounter "Deleting previous Shadow Copy"
									try {
										$shadowCopy.Delete()
									}
									catch {
										$output = "ERROR: Could not delete Shadow Copy"
										$emailBody = "$emailBody`r`n$output`r`n$_"
										$error_during_backup = $true
										Write-Host $output  $_
									}
									$num_shadow_copies--
									Write-Host "done`n"
									break
								}
							}
						}
						StepCounter "Creating Shadow Volume Copy"
						try {
							$s1 = (gwmi -List Win32_ShadowCopy).Create("$backup_source_drive_letter\", "ClientAccessible")
							$s2 = gwmi Win32_ShadowCopy | ? { $_.ID -eq $s1.ShadowID }

							if ($s1.ReturnValue -ne 0 -OR !$s2) {
								#ToDo add explanation of return codes http://msdn.microsoft.com/en-us/library/aa389391%28v=vs.85%29.aspx
								throw "Shadow Copy Creation failed. Return Code: " + $s1.ReturnValue
							}

							$echo="Shadow Volume ID: $($s2.ID)"
							$echo+="`nShadow Volume DeviceObject: $($s2.DeviceObject)"
							Write-Host $echo
							WriteLog "$echo`n"
							
							$shadowCopies = Get-WMIObject -Class Win32_ShadowCopy

							Write-Host "done`n"

							$backup_source_path = $s2.DeviceObject+$backup_source_path
							$num_shadow_copies++
							$shadow_drive_letter = $backup_source_drive_letter
						}
						catch {
							$output = "ERROR: Could not create Shadow Copy`r`n$_ `r`nATTENTION: Skipping creation of Shadow Volume Copy. ATTENTION: if files are changed during the backup process, they might end up being corrupted in the backup!`r`n"
							$emailBody = "$emailBody`r`n$output`r`n"
							$error_during_backup = $true

							Write-Host $output
							WriteLog "$output"

							$backup_source_path = $backup_source
							$NoShadowCopy = $True
						}
					}
				} else {
					# We were asked to do shadow copy but the source is a UNC path.
					$output = "Skipping creation of Shadow Volume Copy because source is a UNC path"
					StepCounter "$output"
					$echo="ATTENTION: if files are changed during the backup process, they might end up being corrupted in the backup!`n"
					Write-Host $echo
					WriteLog "$echo"					
					$backup_source_path = $backup_source
				}
			}
			else {
				$output = "Skipping creation of Shadow Volume Copy"
				StepCounter "$output"
				$echo="ATTENTION: if files are changed during the backup process, they might end up being corrupted in the backup!"
				Write-Host $echo
				WriteLog "$echo"					
				$backup_source_path = $backup_source
			} # End of check for ShadowCopy

			StepCounter "Running backup"

			$echo="Source: $backup_source_path"
			$echo+="`nDestination: $actualBackupDestination$backupMappedString`n"
			Write-Host $echo
			WriteLog "$echo"

			$yearBackupsKeptText = ""
			#It's used by delorean copy as source folder
			$lastBackupFolderName = ""
			# Contains the list of the old all backups to be checked for delete
			$lastBackupFolders = @()
			# Contains the list of the backups to keep
			# To keep one backup, add to this list
			$lastBackupsToKeep = @()
			# Name of current backup folder.
			# You can use to filter current backup from collections like $lastBackupsToKeep and $lastBackupFolders
			$currentBackupFolderName="$backup_source_folder - $dateTime"
				
			If (Test-Path $selectedBackupDestination -pathType container) {

				#escape $backup_source_folder if we are doing backup of a full disk like D:\ to folder [D]
				if ($backup_source_folder -match "\[[A-Z]\]") {
					$escaped_backup_source_folder = '\' + $backup_source_folder
				}
				else {
					$escaped_backup_source_folder = $backup_source_folder
				}
				
				# Contains the list of the backups belonging to source
				$lastBackupFolders = @(GetAllBackupsSourceItems $selectedBackupDestination $escaped_backup_source_folder)
				if($lastBackupFolders.length -gt 0)
				{
					$lastBackupFolderName = $lastBackupFolders[-1]
				}
			}
			
			if ($traditional -eq $True) {
				$traditionalArgument = " --traditional "
			} else {
				$traditionalArgument = ""
			}

			if ($noads -eq $True) {
				$noadsArgument = " --noads "
			} else {
				$noadsArgument = ""
			}

			if ($noea -eq $True) {
				$noeaArgument = " --noea "
			} else {
				$noeaArgument = ""
			}

			if ($splice -eq $True) {
				$spliceArgument = " --splice "
			} else {
				$spliceArgument = ""
			}			

			if ($unroll -eq $True) {
				$unrollArgument = " --unroll "
			} else {
				$unrollArgument = ""
			}			
			
			if ($backupModeACLs -eq $True) {
				$backupModeACLsArgument = " --backup "
			} else {
				$backupModeACLsArgument = ""
			}				
			
			if ($timeTolerance -ne 0) {
				$timeToleranceArgument = " --timetolerance $timeTolerance "
			} else {
				$timeToleranceArgument = ""
			}

			$excludeFilesString=" "
			foreach ($item in $excludeFiles) {
				if ($item -AND $item.Trim()) {
					$excludeFilesString = "$excludeFilesString --exclude `"$item`" "
				}
			}

			$excludeDirsString=" "
			foreach ($item in $excludeDirs) {
				if ($item -AND $item.Trim()) {
					$excludeDirsString = "$excludeDirsString --excludedir `"$item`" "
				}
			}

			#We don't need put spaces between parameters because on declaration we already put them.
			$commonArgumentString = "$traditionalArgument$noadsArgument$noeaArgument$timeToleranceArgument$excludeFilesString$excludeDirsString$spliceArgument$unrollArgument$backupModeACLsArgument".trim()

			if ($LogFile) {
				$logFileCommandAppend = " >> `"$LogFile`""
			}

			$start_time = get-date -f "yyyy-MM-dd HH-mm-ss"

			$unrollLogMessage="Using Unroll mode:`r`n`tAll Outer Junctions/Symlink Directories will be rebuild inside the hierarchy at the destination location.`r`n`tOuter Symlink Files will be copied to the destination location.`r`n`tsee http://schinagl.priv.at/nt/ln/ln.html#unroll for more information.`r`n"
			if (($lastBackupFolderName -eq "") -or $FullBackup) {
				$cmdString="`"$lnPath`" $commonArgumentString --copy `"$backup_source_path`" `"$actualBackupDestination`""

				$echo="Full copy from $backup_source_path to $actualBackupDestination$backupMappedString`n"
				Write-Host $echo
				WriteLog "$echo"
				
				#Verbose. Showing ln.exe command line
				if($unroll -eq $True) {Verbose $unrollLogMessage}
				Verbose $cmdString
				
				`cmd /c  "`"$cmdString $logFileCommandAppend 2`>`&1 `""`
			} else {
				$cmdString="`"$lnPath`" $commonArgumentString --delorean `"$backup_source_path`" `"$selectedBackupDestination\$lastBackupFolderName`" `"$actualBackupDestination`""

				$echo="Delorean copy from $backup_source_path to $actualBackupDestination$backupMappedString against $selectedBackupDestination\$lastBackupFolderName`n"
				Write-Host $echo
				WriteLog "$echo"
				
				#Verbose. Showing ln.exe command line
				if($unroll -eq $True) {Verbose $unrollLogMessage}
				Verbose $cmdString

				`cmd /c  "`"$cmdString $logFileCommandAppend 2`>`&1 `""`
			}
			
			$saved_lastexitcode = $LASTEXITCODE
			if ($saved_lastexitcode -ne 0) {
				$output = "`n`nERROR: the ln command ended with exit code [$saved_lastexitcode]" 
				$error_during_backup = $true
				$ln_error = $true
			} else {
				$output = ""
				$ln_error = $false
			}

			#Here we initialize $summary first time
			$summary = ""
			if ($LogFile) {
				$backup_response = get-content "$LogFile"
				foreach ( $line in $backup_response.length..1 ) {
					$summary =  $backup_response[$line] + "`n" + $summary
					
					#do we need this line if we already checked for the exitcode?
					if ($backup_response[$line] -match '(.*):\s+(?:\d+(?:\,\d*)?|-)\s+(?:\d+(?:\,\d*)?|-)\s+(?:\d+(?:\,\d*)?|-)\s+(?:\d+(?:\,\d*)?|-)\s+(?:\d+(?:\,\d*)?|-)\s+(?:\d+(?:\,\d*)?|-)\s+([1-9]+\d*(?:\,\d*)?)') {
						$error_during_backup = $true
					}
					if ($backup_response[$line] -match '.*Total\s+Copied\s+Linked\s+Skipped.*\s+Excluded\s+Failed.*') {
						break
					}
				}
			}

			Write-Host "done`n"

			$summary = "`n------Summary-----`nBackup AT: $start_time FROM: $backup_source TO: $selectedBackupDestination$backupMappedString`n" + $summary
			Write-Host $summary
			WriteLog "`$summary`r`n"
			
			$emailBody = $emailBody + $summary

			if ($ln_error)
			{
				$emailBody = "$emailBody`r$output`r`n"
				Write-Host $output
				WriteLog $output
			}
			else
			{
					# Add current backup to lastBackupsToKeep
				$lastBackupsToKeep+=$currentBackupFolderName
			}

				# If error on ln.exe, check if backup directory have been created
			if(($ln_error -eq $False) -or (Test-Path -Path "$actualBackupDestination"))
			{
				#.PARAMETER SkipIfNoChanges
				#Parse log file for changes on source and delete backup folder if not changes.
				#Thus, we get less backup folders and therefore less hard links. Delaying the possibility of reaching the NTFS link limit of 1023.		
				if (($backup_response) -and ($SkipIfNoChanges -eq $True)) {

					StepCounter "Checking for changes (Parameter SkipIfNoChanges On)"

					# If changes, current scope $lastBackupsToKeep and $lastBackupFolders will be updated
					SkipIfNoChanges $backup_response $actualBackupDestination$backupMappedString $currentBackupFolderName ([Ref]$lastBackupsToKeep) ([Ref]$lastBackupFolders)
					#$lastBackupFolderName = $lastBackupFolders[-1]		ZZZ	Don't need because it's not used later
				}
				
				StepCounter "Deleting old backups"

				#.PARAMETER ClosestRotation
				# Strategy of snapshot rotation keeping the most closest and the first backup in a time period.
				if ($ClosestRotation -eq $True) {				
					ClosestRotation ([Ref]$lastBackupsToKeep) ([Ref]$lastBackupFolders)
				}

				# Parameter backupsToKeepPerYear
				if(($lastBackupFolders.length -gt 0) -and ($backupsToKeepPerYear -gt 0))
				{			
					GetBackupsToKeepPerYear $backupsToKeepPerYear ([Ref]$lastBackupsToKeep) ([Ref]$lastBackupFolders) $backup_source_folder
				}

				$summary=""

				#INIT PARAMETER backupsToKeep				
				$totalBackupsToDelete=$lastBackupFolders.length
				if($totalBackupsToDelete -gt 0)
				{
					if($totalBackupsToDelete -gt $backupsToKeep)
					{					
						$echo="Selected $totalBackupsToDelete old backup(s) to delete."
						Write-Host "$echo`n"
						$summary+="`r`n$echo`r`n"

						$echo="Keeping a maximum of $backupsToKeep regular backup(s)."
						$echo+=" (Parameter backupsToKeep=$backupsToKeep)"
						Write-Host "$echo`n"
						$summary+="`r`n$echo`r`n"

						WriteLog $summary
						$emailBody = $emailBody + $summary

						$lastBackupsToKeep+=$lastBackupFolders[($backupsToKeep * -1)..-1]
						CheckLastArrayItems ([Ref]$lastBackupFolders) ([Ref]$lastBackupsToKeep)
					}
					else
					{
						$echo=("Found " + ($totalBackupsToDelete) + " regular backup(s), keeping all (maximum is $backupsToKeep)")
						$lastBackupsToKeep+=$lastBackupFolders
						$lastBackupFolders=@()
					}
				}
				#END PARAMETER backupsToKeep

				#Always lastBackupFolders items will be deleted!!
				DeleteBackupFolders $selectedBackupDestination $lastBackupFolders
		
					#Delete log files belonging to deleted backup folders
				if($lastBackupFolders.length -gt 0)
				{
					$echo="Deleting log files belonging old backup(s) deleted."
					Write-Host "$echo"
					WriteLog "$echo"
					$logFilesToDelete=@(GetOrphanLogFiles $selectedBackupDestination $lastBackupFolders)
					
					if($logFilesToDelete.length -gt 0)
					{
						DeleteLogFiles $logFileDestination $logFilesToDelete
					}
					else
					{
						$echo="Log files belonging to old backup(s) not found."
						Write-Host "$echo"
						WriteLog "$echo"
					}					
				}
			}
		} else {
			# The backup source does not exist - there was no point processing this source.
			$output = "ERROR: Backup source does not exist - $backup_source - backup NOT done for this source`r`n"
			$emailBody = "$emailBody`r`n$output`r`n"
			$error_during_backup = $true
			Write-Host $output
			WriteLog $output
		}
	}

	if (($deleteOldLogFiles -eq $True) -and ($logFileDestination)) {
		StepCounter "Deleting old log files" -counter 1

		$lastLogFiles = @(GetAllLogsFiles $logFileDestination)

		#INIT logFilesToKeep applied to logFiles
		
			# If $logFilesToKeep<=0, keep at least current log file
		if($logFilesToKeep -le 0) {$logFilesToKeep=1}
		
		$summary=""
		#No need to add 1 here because the new log existed already when we checked for old log files
		$totalLogFilesToDelete = $lastLogFiles.length
		$echo="Selected $totalLogFilesToDelete log file(s) to delete."
		Write-Host "$echo`n"
		$summary+="`r`n$echo`r`n"

		$echo="Keeping a maximum of $logFilesToKeep log files(s)."
		$echo+=" (Using Parameter backupsToKeep)"
		Write-Host "$echo`n"
		$summary+="`r`n$echo`r`n"

		WriteLog $summary
		$emailBody = $emailBody + $summary

		# Exclude from deletion the current log file
		$lastLogFiles = @(ArrayFilter $lastLogFiles @($dateTime))

		# Include on deletion only orphan log files
		$lastLogFiles = @(GetOrphanLogFiles $selectedBackupDestination $lastLogFiles)
		
		$totalLogFilesToDelete=$lastLogFiles.length - $logFilesToKeep
		
		if($totalLogFilesToDelete -le 0)
		{
			$lastLogFiles=@()
		}
		
		if($lastLogFiles.length -gt $totalLogFilesToDelete)
		{
			$lastLogFiles=$lastLogFiles[0..($totalLogFilesToDelete - 1)]
		}

		#END PARAMETER backupsToKeep applied to logFiles
		
		#Allways lastLogFiles items will be deleted!!
		DeleteLogFiles $logFileDestination $lastLogFiles
	}

	# We have processed each backup source. Now cleanup any remaining shadow copy.
	if ($num_shadow_copies -gt 0) {
		# Delete the last shadow copy
		foreach ($shadowCopy in $shadowCopies) {
		if ($s2.ID -eq $shadowCopy.ID) {
			StepCounter "Deleting last Shadow Copy"
			try {
				$shadowCopy.Delete()
			}
			catch {
				$output = "ERROR: Could not delete Shadow Copy. "
				$emailBody = "$emailBody`r`n$output`r`n$_"
				$error_during_backup = $true
				Write-Host $output  $_
			}
			$num_shadow_copies--
			Write-Host "done`n"
			break
			}
		}
	}

} else {
	if ($parameters_ok -eq $True) {
		if ($doBackup -eq $True) {
			# The destination drive or \\server\share does not exist.
			$output = "ERROR: Destination drive or share $backupDestinationTop$backupMappedString does not exist - backup NOT done`r`n"
		} else {
			# The backup was not done because localSubnetOnly was on, and the destination \\server\share is not in the local subnet.
			$output = "ERROR: Destination share $backupDestinationTop$backupMappedString is not in a local subnet - backup NOT done`r`n"
		}
	} else {
		# There was some error in the supplied parameters.
		# The specific problem will have been mentioned in the email body/log file earlier.
		# Put a general message here.
		$output = "ERROR: There was a problem with the input parameters"
	}
	$emailBody = "$emailBody`r`n$output`r`n"
	$error_during_backup = $true
	Write-Host $output
	WriteLog "$output`r`n"
}

if ($emailTo -AND $emailFrom -AND $SMTPServer) {
	# Restart Stepcounter to 1
	StepCounter 1
		
	$echo="============Sending Email============"
	Write-Host $echo
	WriteLog "$echo`n"
	
	if ($LogFile) {
		StepCounter "Zipping log file"
		$zipFilePath = "$LogFile.zip"
		$fileToZip = get-item $LogFile

		try
		{
			New-Item $zipFilePath -type file -force -erroraction stop | Out-Null
			if (-not (test-path $zipFilePath)) {
			  set-content $zipFilePath ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
			}

			$ZipFile = (new-object -com shell.application).NameSpace($zipFilePath)
			$zipfile.CopyHere($fileToZip.fullname)

			$timeSlept = 0
			while ($zipfile.Items().Count -le 0 -AND $timeSlept -le $maxMsToSleepForZipCreation ) {
				Start-sleep -milliseconds $msToWaitDuringZipCreation
				$timeSlept = $timeSlept + $msToWaitDuringZipCreation
			}
			$attachment = New-Object System.Net.Mail.Attachment("$zipFilePath" )
		}
		catch {
			$error_during_backup = $True
			$output = "`r`nERROR: Could not create log ZIP file. Will try to attach the unzipped log file and hope it's not to big.`r`n$_`r`n"
			$emailBody = "$emailBody`r`n$output`r`n"
			Write-Host $output
			WriteLog "$output`r`n"
			$attachment = New-Object System.Net.Mail.Attachment("$LogFile" )
		}
	}

	if ($error_during_backup) {
		$EmailSubject = "ERROR - $EmailSubject"
	}
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($emailFrom,$emailTo,$emailSubject,$emailBody)

	if ($LogFile) {
		$SMTPMessage.Attachments.Add($attachment)
	}
	$SMTPClient = New-Object Net.Mail.SmtpClient($SMTPServer, $SMTPPort)

	$SMTPClient.Timeout = $SMTPTimeout
	if ($NoSMTPOverSSL -eq $False) {
		$SMTPClient.EnableSsl = $True
	}

	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPassword);

	$emailSendSucess = $False
	StepCounter "Sending email"

	while ($emailSendRetries -gt 0 -AND !$emailSendSucess) {
		try {
			$emailSendRetries--
			$SMTPClient.Send($SMTPMessage)
			$emailSendSucess = $True
		} catch {
			if ($StepTiming -eq $True) {
				$stepTime = get-date -f "yyyy-MM-dd HH-mm-ss"
			}
			$output = "ERROR: $stepTime Could not send Email.`r`n$_`r`n"
			Write-Host $output
			WriteLog "$output`r`n"
		}

		if (!$emailSendSucess) {
			Start-sleep -milliseconds $msToPauseBetweenEmailSendRetries
		}
	}

	if ($LogFile) {
		$attachment.Dispose()
	}

	Write-Host "done"
}

if ($substDone) {
	# Delete any drive letter substitution done earlier
	# Note: the subst drive might have contained the log file, so we cannot delete earlier since it is needed to zip and email.
	$echo="`nRemoving subst of $substDrive`n"
	Write-Host $echo
	WriteLog "$echo`n"
	
	subst "$substDrive" /D
}

if (-not ([string]::IsNullOrEmpty($postExecutionCommand))) {
	StepCounter "`nrunning postexecution command ($postExecutionCommand)`n"
	$output = `cmd /c  `"$postExecutionCommand`"`

	$output += "`n"
	Write-Host $output
	WriteLog "$output`r`n"
}
