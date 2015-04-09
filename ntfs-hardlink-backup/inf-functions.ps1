<#
.DESCRIPTION
	Powershell General Functions
	(Functions from International-Nepal-Fellowship original version)
	
	Functions to be used by anothers scripts
	File especially created to be used by the script NTFS-HARDLINK-BACKUP

.NOTES
	Author    : International-Nepal-Fellowship
#>
#To include only 1 time
$included_inf_functions=$True

Function Get-IniContent
{

	<#
	.Synopsis
		Gets the content of an INI file

	.Description
		Gets the content of an INI file and returns it as a hashtable

	.Notes
		Author    : Oliver Lipkau <oliver@lipkau.net>
		Blog      : http://oliver.lipkau.net/blog/
		Date      : 2014/06/23
		Version   : 1.1

		#Requires -Version 2.0

	.Inputs
		System.String

	.Outputs
		System.Collections.Hashtable

	.Parameter FilePath
		Specifies the path to the input file.

	.Example
		$FileContent = Get-IniContent "C:\myinifile.ini"
		-----------
		Description
		Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

	.Example
		$inifilepath | $FileContent = Get-IniContent
		-----------
		Description
		Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

	.Example
		C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
		C:\PS>$FileContent["Section"]["Key"]
		-----------
		Description
		Returns the key "Key" of the section "Section" from the C:\settings.ini file

	.Link
		Out-IniFile
	#>

	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]
		[Parameter(ValueFromPipeline=$True,Mandatory=$True)]
		[string]$FilePath
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
	{
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

		#changed from HashTable to OrderedDictionary to keep the sections in the order they were added - Artur Neumann
		$ini = New-Object System.Collections.Specialized.OrderedDictionary
		switch -regex -file $FilePath
		{
			"^\[(.+)\]$" # Section
			{
				$section = $matches[1]
				# Added ToLower line to make INI file case-insensitive - Phil Davis
				$section = $section.ToLower()
				$ini[$section] = @{}
				$CommentCount = 0
			}
			"^(;.*)$" # Comment
			{
				if (!($section))
				{
					$section = "No-Section"
					$ini[$section] = @{}
				}
				$value = $matches[1]
				$CommentCount = $CommentCount + 1
				$name = "Comment" + $CommentCount
				$ini[$section][$name] = $value
			}
			"(.+?)\s*=\s*(.*)" # Key
			{
				if (!($section))
				{
					$section = "No-Section"
					$ini[$section] = @{}
				}
				$name,$value = $matches[1..2]
				# Added ToLower line to make INI file case-insensitive - Phil Davis
				$name = $name.ToLower()
				$ini[$section][$name] = $value
			}
		}
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
		Return $ini
	}

	End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function Get-IniParameter
{
	# Note: iniFileContent dictionary is not passed in each time.
	# Just use the global value to reference that.
	[CmdletBinding()]
	Param(
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$ParameterName,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$True)]
		[string]$FQDN,
		[ValidateNotNullOrEmpty()]
		[Parameter(Mandatory=$False)]
		[switch]$doNotSubstitute=$False
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
	{
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for IniSection: $FQDN and ParameterName: $ParameterName"

		# Use ToLower to make all parameter name comparisons case-insensitive
		$ParameterName = $ParameterName.ToLower()
		$ParameterValue = $Null

		$FQDN=$FQDN.ToLower()
		
		#search first the "common" section for the parameter, this will have the lowest priority
		#as the parameter can be overwritten by other sections
		if ($global:iniFileContent.Contains("common")) {
			if (-not [string]::IsNullOrEmpty($global:iniFileContent["common"][$ParameterName])) {
				$ParameterValue = $global:iniFileContent["common"][$ParameterName]
			}
		}

		#search if there is a section that matches the FQDN 
		#this is the second highest priority, as the parameter can still be overwritten by the
		#section that meets exactly the FQDN
		#If there is more than one section that matches the FQDN with the same parameter
		#the section furthest down in the ini file will be used 
		foreach ($IniSection in $($global:iniFileContent.keys)){
			$EscapedIniSection=$IniSection -replace "([\-\[\]\{\}\(\)\+\?\.\,\\\^\$\|\#])",'\$1'
			$EscapedIniSection=$IniSection -replace "\*",'.*'
			if ($FQDN -match "^$EscapedIniSection$") {
				if (-not [string]::IsNullOrEmpty($global:iniFileContent[$IniSection][$ParameterName])) {
					$ParameterValue = $global:iniFileContent[$IniSection][$ParameterName]
				}
			}
		}

		#see if there is section that is called exactly the same as the computer (FQDN)
		#this is the highest priority, so if the same parameters are used in other sections
		#this section will overwrite them
		if ($global:iniFileContent.Contains($FQDN)) {
			if (-not [string]::IsNullOrEmpty($global:iniFileContent[$FQDN][$ParameterName])) {
				$ParameterValue = $global:iniFileContent[$FQDN][$ParameterName]
			}
		}
			
		#replace all <parameter> with the parameter values
		if ($doNotSubstitute -eq $False) {
			$substituteMatches=$ParameterValue | Select-String -AllMatches '<[^<]+?>' | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value			
			
			foreach ($match in $substituteMatches) {
				if(![string]::IsNullOrEmpty($match)) {            
					$match=$($match.Trim())
					$cleanMatch=$match.Replace("<","").Replace(">","")
					if ($(test-path env:$($cleanMatch))) {					
						$substituteValue=$(get-childitem -path env:$($cleanMatch)).Value
						$ParameterValue =$ParameterValue.Replace($match,$substituteValue)
					}
				}
			}
		}
		
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for IniSection: $FQDN and ParameterName: $ParameterName ParameterValue: $ParameterValue"
		Return $ParameterValue
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

Function Is-TrueString
{
	# Pass in a string (or nothing) and return a boolean deciding if the string
	# is "1", "true", "t" (True) or otherwise it is (False)
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$False)]
		[string]$TruthString
	)

	Begin
		{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

	Process
    {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing for TruthString: $TruthString"

		# Use ToLower to make comparisons case-insensitive
		$TruthString = $TruthString.ToLower()
		$ParameterValue = $Null

		if (($TruthString -eq "t") -or ($TruthString -eq "true") -or ($TruthString -eq "1")) {
			$TruthValue = $True
		} else {
			$TruthValue = $False
		}

		Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing for TruthString: $TruthString TruthValue: $TruthValue"
		Return $TruthValue
    }

    End
	{Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}