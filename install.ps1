param (
	[string]$installationPath,
	[boolean]$reset=$False,
	[boolean]$purge=$False,
	[boolean]$force=$False
)

$files = @( 'Checkmarx Access Control\wwwroot\index.html', 'CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx' );

Write-Host "Parameters:"
Write-Host "-installationPath [C:\Program Files\Checkmarx]`n`tPath to installation"
Write-Host "-reset `$True `n`tReset files to original backups"
Write-Host "-purge `$True `n`tReset files to originals, remove backups, and remove CxP-Tweaks.js file"
Write-Host "-force `$True `n`tForce creating a new backup file (after platform upgrade)`n"

function find_in_file {
	param ( $file, $string )
	foreach($line in [System.IO.File]::ReadLines($file))
	{
		if ( $line -match $string ) {
			return $True
		}
	}
	return $False
}

function do_backup {
	foreach ( $file in $files ) {
		$orig = "$installationPath\$file"
		$backup = "$orig.cxpt.bak"
		
		if ( (Test-Path -Path $backup) -And $force -ne $True ) {
			Write-Host "Backup $backup already exists, not forced through -force parameter."
		} else {
			if ( find_in_file -file $orig -string "CxWebClient/CxP-Tweaks.js" ) {
				Write-Host "File $orig already updated to include 'CxP-Tweaks.js', skipping backup"
			} else {
				Write-Host "Creating backup $backup"			
				Copy-Item $orig -Dest $backup
			}
		}
	}
}

function do_reset {
	foreach ( $file in $files ) {
		$orig = "$installationPath\$file"
		$backup = "$orig.cxpt.bak"
		
		if ( Test-Path -Path $backup ) {
			Write-Host "Restoring backup to $orig"
			Copy-Item $backup -Dest $orig -Force
		} else {
			Write-Host "Backup file $backup does not exist to restore."
		}
	}
}

function do_purge {
	foreach ( $file in $files ) {
		$orig = "$installationPath\$file"
		$backup = "$orig.cxpt.bak"
		
		if ( Test-Path -Path $backup ) {
			Write-Host "Restoring backup to $orig"
			Copy-Item $backup -Dest $orig -Force
			Write-Host "Removing backup $backup"
			Remove-Item $backup 
		} else {
			Write-Host "Backup file $backup does not exist to restore."
		}
	}
	
	$CxP_path = "$installationPath\CheckmarxWebPortal\Web\CxP-Tweaks.js"
	if ( Test-Path -Path $CxP_path ) {
		Write-Host "Removing $CxP_path"
		Remove-Item $CxP_path
	} else {
		Write-Host "File $CxP_path doesn't exist to remove"
	}
	
	Write-Host "You may be required to manually check and remove previous backups named: *.cxpt.bak"
}

function stage_insert {
	param(  [string]$srcfile,
			[string]$stagefile,
			$condition,
			[string]$inserted_line )
	
	$backup = "$srcfile.cxpt.bak"
	#Write-Host "Stage insert $srcfile $stagefile $backup" 
	
	if ( (Test-Path -Path $backup) -ne $True ) {
			Write-Host "Backup file $backup does not exist, skipping"
			return;
	}
	if ( Test-Path -Path $stagefile ) { Remove-Item $stagefile }	
	
	Write-Host "Creating $stagefile"
	$ret = New-Item -Path $stagefile -Force
	$linecount = 0;
	foreach($line in [System.IO.File]::ReadLines($backup))
	{
		$linecount++;
		if ( $line -match "/CxWebClient/CxP-Tweaks.js" ) {
			Write-Host "File already contains reference to CxP-Tweaks.js, skipping"
			Remove-Item $stagefile
			return
		}
		
		if ( $line -match $condition ) {
			Add-Content -Path $stagefile -Value $inserted_line
			Write-Host " - Inserting line $linecount`: $inserted_line"
		}
		Add-Content -Path $stagefile -Value $line
	}
	
	# changes are done, replace the file.
	if ( Test-Path -Path $stagefile ) {
		Remove-Item $srcfile
		Move-Item -Path $stagefile -Destination $srcfile
	}
}

function stage_install {
	Write-Host "Staging installation"
	
	# first do the access control index.html
	$srcfile = "$installationPath\Checkmarx Access Control\wwwroot\index.html"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.stage" -condition [regex]".*</body>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"
	
	$srcfile = "$installationPath\CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.stage" -condition "</header>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"
}

if ( $installationPath -eq '' ) {
	$loop = 1;
	while ( $loop ) {	
		$installationPath = 'C:\Program Files\Checkmarx'
		$ret = Read-Host "Enter the path to your Checkmarx installation [$installationPath]"
		if ( $ret -ne "" ) {
			$installationPath = $ret;
		}
		if ( Test-Path -Path $installationPath ) {
			Write-Host " - Verified $installationPath exists"
			$installationPath = $installationPath
			$loop = 0;
		} else {
			Write-Host " - Path $installationPath does not exist. Please enter the path to your Checkmarx installation on this host."
		}
	}
}

if ( $reset ) {
	$confirmation = Read-Host "Resetting back to original backups, continue? [y/n]"
	if ( $confirmation -ne 'y' -and $confirmation -ne 'Y' ) {
		Write-Host "Canceled."
		exit;
	}
	do_reset
	exit
}

if ( $purge ) {
	$confirmation = Read-Host "Resetting back to original backups and removing backups and CxP-Tweaks.js, continue? [y/n]"
	if ( $confirmation -ne 'y' -and $confirmation -ne 'Y' ) {
		Write-Host "Canceled."
		exit;
	}
	do_purge
	exit
}



# copy the js file
$CxP_dest = "$installationPath\CheckmarxWebPortal\Web\"
Write-Host "Copying CxP-Tweaks.js to $CxP_dest"
Copy-Item CxP-Tweaks.js -Destination $CxP_dest -Force

do_backup

stage_install