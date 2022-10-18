param (
	[string]$installationPath,
	[boolean]$restore=$False,
	[boolean]$purge=$False,
	[boolean]$force=$False
)

$files = @( 'Checkmarx Access Control\wwwroot\index.html', 'CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx', 'CheckmarxWebPortal\Web\ScanQueryDescription.aspx', 'CheckmarxWebPortal\Web\ViewerGrid.aspx' );

Write-Host "Parameters:"
Write-Host "-installationPath [C:\Program Files\Checkmarx]`n`tPath to installation"
Write-Host "-restore `$True `n`tRestore files from original backups"
Write-Host "-purge `$True `n`tRestore files from original backups, remove backups and staging files, and remove CxP-Tweaks.js file"
Write-Host "-force `$True `n`tForce creating a new backup file (during installation) or restoring from backup (during restore/purge)`n"

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
    Write-Host "`nBacking up existing files"
    $backup_count = 0

	foreach ( $file in $files ) {
		$current = "$installationPath\$file"
		$backup = "$current.cxpt.bak"
        $stage = "$current.cxpt.stage"

        if ( $force -ne $True ) {
            if (Test-Path -Path $stage) {
                if ((Get-FileHash -path $current).Hash -eq (Get-FileHash -path $stage).Hash) {
                    if ( Test-Path -Path $backup ) {
                        Write-Host "  Note: The current file ($current) has already been modified and matches the staging file ($stage), and a backup already exists ($backup). Skipping."
                        $backup_count ++
                    } else {
                        Write-Host "`n  Error: The current file ($current) has already been modified and matches the staging file ($stage), but the backup file ($backup) is missing."
                    }
                    continue
                }
                if ( find_in_file -file $current -string "CxWebClient/CxP-Tweaks.js" ) {
                    if ( Test-Path -Path $backup ) {
                        Write-Host "  Note: The current file ($current) already includes CxP-Tweaks.js, but does not match the staging file ($stage) - it may have been manually modified. A backup file ($backup) already exists. Skipping."
                        $backup_count++
                    } else {
                        Write-Host "  Note: The current file ($current) already includes CxP-Tweaks.js, but does not match the staging file ($stage) - it may have been manually modified. A backup file ($backup) does not exist. Skipping."
                    }
                    continue
                }
            }

		    if ( Test-Path -Path $backup ) {
                if ((Get-FileHash -path $current).Hash -eq (Get-FileHash -path $backup).Hash) {
			        Write-Host "  Backup $backup already exists and is identical to $current. Skipping."
                    $backup_count ++
                } else {
                    Write-Host "  Backup $backup already exists but does not match $current. To force a new backup use the parameter -force `$true. Skipping."
                }
                continue
		    }
        }

		Write-Host "  Creating backup $backup"			
		Copy-Item $current -Dest $backup -Force
        $backup_count++
	}
    return $backup_count
}

function do_restore {
    Write-Host "`nRestoring from backup"
    $restore_count = 0
	foreach ( $file in $files ) {
		$current = "$installationPath\$file"
		$backup = "$current.cxpt.bak"
        $stage = "$current.cxpt.stage"

        if ( -Not (Test-Path -Path $backup) ) {
            Write-Host "  Note: Backup file $backup does not exist, some files may have been manually removed. Skipping."
            continue
        }	
        
        if ( (Get-FileHash -Path $current).Hash -eq (Get-FileHash -Path $backup).Hash ) {
            Write-Host "  Note: File $current already matches the backup $backup. Skipping."
            $restore_count++
            continue
        }
        	
        if ( $force -ne $True ){
            if ( -Not (Test-Path -Path $stage) ) {
                Write-Host "  Note: Staging file $stage does not exist, some files may have been manually removed. Skipping."
                continue
            }

            if ( -Not ((Get-FileHash -Path $current).Hash -eq (Get-FileHash -Path $stage).Hash) ) {
                Write-Host "`n  Error: The current file ($current) does not match the staging file ($stage). `n    This may be due to running a hotfix or update, in which case the backup is from an older version. Skipping the restore.`n    Please review the contents of these files. If you wish to force the restore use the parameter -force `$true."
                continue
            }
        }

		Write-Host "  Restoring $current from backup $backup"
		Copy-Item $backup -Dest $current -Force		
        $restore_count++
	}

    Write-Host "Restored $restore_count out of $($files.Count) files."

    return $restore_count
}

function do_purge {
    $ret = do_restore
    if ( $ret -ne $files.Count -and $force -ne $True ) {
        Write-Host "`nError: Unable to restore all files from backup, cancelling the purge. To force, use the parameter -force $True"
        return
    }

    Write-Host "`nPurging CxP-Tweaks from the system"
	foreach ( $file in $files ) {
		$current = "$installationPath\$file"
		$backup = "$current.cxpt.bak"
        $stage = "$current.cxpt.stage"
		
		if ( Test-Path -Path $backup ) {
			Write-Host "  Removing backup $backup"
			Remove-Item $backup 
		} else {
			Write-Host "  Note: Backup file $backup does not exist to remove."
		}

        if ( Test-Path -Path $stage ) {
            Write-Host "  Removing staging file $stage"
            Remove-Item $stage
        } else {
            Write-HOst "  Note: Staging file $stage does not exist to remove."
        }
	}
	
	$CxP_path = "$installationPath\CheckmarxWebPortal\Web\CxP-Tweaks.js"
	if ( Test-Path -Path $CxP_path ) {
		Write-Host "  Removing $CxP_path"
		Remove-Item $CxP_path
	} else {
		Write-Host "  File $CxP_path doesn't exist to remove"
	}
}

function stage_insert {
	param(  [string]$srcfile,
			[string]$stagefile,
			$condition,
			[string]$inserted_line )
	
	$backup = "$srcfile.cxpt.bak"
	#Write-Host "Stage insert $srcfile $stagefile $backup" 
	
	if ( (Test-Path -Path $backup) -ne $True ) {
		Write-Host "  Backup file $backup does not exist, skipping"
		return;
	}
	if ( Test-Path -Path $stagefile ) { Remove-Item $stagefile }	
	
	Write-Host "  Creating staging file: $stagefile"
	$ret = New-Item -Path $stagefile -Force
	$linecount = 0;
	foreach($line in [System.IO.File]::ReadLines($backup))
	{
		$linecount++;
		if ( $line -match "/CxWebClient/CxP-Tweaks.js" ) {
			Write-Host "    This file already contains reference to CxP-Tweaks.js, skipping"
			Remove-Item $stagefile
			return
		}
		
		if ( $line -match $condition ) {
			Add-Content -Path $stagefile -Value $inserted_line
			Write-Host "   Inserting line $linecount`: $inserted_line"		                
		}
        Add-Content -Path $stagefile -Value $line
	}
	
	# changes are done, replace the file.
	if ( Test-Path -Path $stagefile ) {
		Remove-Item $srcfile
		Copy-Item -Path $stagefile -Destination $srcfile
	}
}

function stage_install {
	Write-Host "`nStaging installation"
	
	$srcfile = "$installationPath\Checkmarx Access Control\wwwroot\index.html"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.cxpt.stage" -condition [regex]".*</body>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"
	
	$srcfile = "$installationPath\CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.cxpt.stage" -condition "</header>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"

    $srcfile = "$installationPath\CheckmarxWebPortal\Web\ScanQueryDescription.aspx"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.cxpt.stage" -condition "</body>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"

    $srcfile = "$installationPath\CheckmarxWebPortal\Web\ViewerGrid.aspx"
	stage_insert -srcfile $srcfile -stagefile "$srcfile.cxpt.stage" -condition "</html>" -inserted_line "    <script type=`"text/javascript`" src=`"/CxWebClient/CxP-Tweaks.js`" defer></script>"


}

if ( $installationPath -eq '' ) {
    $installationPath = 'C:\Program Files\Checkmarx'
}

$loop = 1;
while ( $loop ) {	
	$ret = Read-Host "Enter the path to your Checkmarx installation [$installationPath]"
	if ( $ret -eq "" ) {
		$ret = $installationPath
	}
	if ( Test-Path -Path $ret ) {
		Write-Host "  Verified $ret exists"

		$loop = 0;

        foreach ( $file in $files ) {
		    $current = "$ret\$file"
            if ( -Not (Test-Path -Path $current) ) {
                Write-Host "`n   Error: An expected file $current does not exist. If this is the correct installation folder, this version of Checkmarx may not be supported by this version of CxP-Tweaks"
                $loop = 1;
            }
        }

        if ( $loop -eq 0 ) {
            $installationPath = $ret
        }
	} else {
		Write-Host " - Path $ret does not exist. Please enter the path to your Checkmarx installation on this host."
	}
}

Write-Host "`n`nCurrent installation details:"
$cxpt_count = 0
foreach ( $file in $files ) {
    $current = "$installationPath\$file"
	$backup = "$current.cxpt.bak"
    $stage = "$current.cxpt.stage"

    $backup_status = "No backup"
    $stage_status = "No staged version"
    if ( (Test-Path -Path $backup) ) {
        $backup_status = "Has backup"
    }
    if ( (Test-Path -Path $stage) ) {
        $stage_status = "Has staged version"
    }

    if ( (Test-Path -Path $backup) -and (Get-FileHash -path $current).Hash -eq (Get-FileHash -path $backup).Hash ) {
        Write-Host "  $current`n    Original, $backup_status, $stage_status"
    } elseif ( (Test-Path -Path $stage) -and (Get-FileHash -path $current).Hash -eq (Get-FileHash -path $stage).Hash ) {
        Write-Host "  $current`n    CxP-Tweaks installed, $backup_status, $stage_status"
        $cxpt_count++
    } elseif ( find_in_file -file $current -string "CxWebClient/CxP-Tweaks.js" ) {
        Write-Host "  $current`n    Modified with CxP-Tweaks installed, $backup_status, $stage_status"
        $cxpt_count++
    } else {
        Write-Host "  $current`n    Most likely original, $backup_status, $stage_status"
    }
    
    Write-Host ""
}

$cxPTweaksJS = "CxP-Tweaks.js"

if ( Test-Path -Path "CxP-Tweaks - customized.js" ) {
	$confirmation = Read-Host "A customized version of CxP-Tweaks.js was found in local file 'CxP-Tweaks - customized.js' - deploy this file instead? [Y/n]"
	if ( $confirmation -ne 'n' -and $confirmation -ne 'N' ) {
		Write-Host " - Using customized file 'CxP-Tweaks - customized.js'`n Note: You should compare CxP-Tweaks.js with this customized file to ensure any updates to the original are included."
		$cxPTweaksJS = "CxP-Tweaks - customized.js"
	} else {
		Write-Host " - Using original CxP-Tweaks.js"
	}
} else {
	Write-Host " - Using local CxP-Tweaks.js file. You can copy 'CxP-Tweaks.js' to 'CxP-Tweaks - customized.js' with your customizations and this script will deploy that file instead. This can help to keep your customizations when a new version of CxP-Tweaks.js is published."
}


if ( $restore ) {
	$confirmation = Read-Host "Restoring files from backups, continue? [y/N]"
	if ( $confirmation -ne 'y' -and $confirmation -ne 'Y' ) {
		Write-Host "Canceled."
		exit;
	}
	$ret = do_restore
	exit
} elseif ( $purge ) {
	$confirmation = Read-Host "Resetting back to original backups and removing backups and CxP-Tweaks.js, continue? [y/N]"
	if ( $confirmation -ne 'y' -and $confirmation -ne 'Y' ) {
		Write-Host "Canceled."
		exit;
	}
	do_purge
	exit
} elseif ( $cxpt_count -eq $files.Count ) {
    Write-Host "`nCxP-Tweaks.js is already present in all $cxpt_count files. Copying $cxPTweaksJS file only."
    $CxP_dest = "$installationPath\CheckmarxWebPortal\Web\CxP-Tweaks.js"
    Copy-Item $cxPTweaksJS -Destination $CxP_dest -Force
    exit;
} else {
    # disclaimer
    Write-Host "`nThis script will modify the following files:"
    $backup_count = 0
    foreach ( $file in $files ) {
    	$current = "$installationPath\$file"
		$backup = "$current.cxpt.bak"
        $stage = "$current.cxpt.stage"

        Write-Host "  $current"
        if ( Test-Path -Path $backup ) {
            $backup_count++
        }
    }

    if ( $backup_count -ne $files.Count ) {
        Write-Host "`nPlease ensure that you have manually created a backup of these files before proceeding."
    }

    $confirmation = Read-Host "`nBegin installation? [y/N]"
    if ( $confirmation -ne 'y' -and $confirmation -ne 'Y' ) {
	    Write-Host "Canceled."
	    exit;
    }
}



# copy the js file
$CxP_dest = "$installationPath\CheckmarxWebPortal\Web\CxPTweaks.js"
Write-Host "Copying $cxPTweaksJS to $CxP_dest"
Copy-Item $cxPTweaksJS -Destination $CxP_dest -Force

$res = do_backup
if ( $force -ne $True -and $res -ne $files.Count ) {
    Write-Host "`nError: Unable to backup all files, cancelling."
    exit
}

stage_install