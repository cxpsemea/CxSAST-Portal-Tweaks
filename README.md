# Checkmarx Portal Tweaks

This was developed against Checkmarx version 9.5.0 and tested against 9.4.0, 9.4.0+HF20, and 9.4.5+HF20 (including engine pack 5)

This modifies the following files:
1. Checkmarx\Checkmarx Access Control\wwwroot\index.html
2. Checkmarx\CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx
3. Checkmarx\CheckmarxWebPortal\Web\ScanQueryDescription.aspx
4. Checkmarx\CheckmarxWebPortal\Web\ViewerGrid.aspx

Ensure you test in a test environment prior to rolling out to Production. The above files are backed up (with a .bak extension) but consider creating additional additional backups manually also.

A set of customizations for the Checkmarx Portal, driven by JavaScript. This collection of tweaks includes:
1. Tweaks to the login page (removing the "Forgot Password" link, adding custom buttons)
2. Adding custom Banners / notifications for informing users of events, outages, or services (Onboarding/optimization)
3. Changing the size of tables in the UI (Projects, ProjectState, Scans, and Queue pages)
4. Disabling the Queue Refresh
5. Removing buttons from the top-right area (Support & Documentation, Codebashing)
6. Adding custom buttons to the top-right area
7. Randomizing scheduled scan time when editing an existing project

# Installation

Clone this git repo somewhere.

## Configuration

Edit the "CxP-Tweaks.js" file and customize the configuration options as indicated at the top of the file.
Ensure that you have updated this file prior to deploying it.

## Automated Installation

Use the install.ps1 powershell script to deploy CxP-Tweaks to a target Checkmarx installation folder.

Initial installation: .\install.ps1

Redeploy after modifying CxP-Tweaks.js: .\install.ps1

Re-installation after a hotfix or upgrade: .\install.ps1 -force $true

Reset modified files to original: .\install.ps1 -reset $true

Reset & remove CxP-Tweaks: .\install.ps1 -purge $true

Parameter description:
 - installationPath can be used to set the installation folder
 - force will update the backup files (\*.cxpt.bak) from the original files even if the backup file already exists, useful if you installed CxP-Tweaks before but an update reset the files
 - reset will copy the backups (\*.cxpt.bak) over the original files
 - purge will reset the files and remove the backups and CxP-Tweaks.js

## Manual Deployment

The recommended method to deploy this script is:
- edit the CxP-Tweaks.js file to customize the settings for your environment.
- place the CxP-Tweaks.js file within the Checkmarx installation's WebPortal folder (by default: C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\)
 - in a High-Availability or Distributed environment, CxP-Tweaks.js must be placed on every server hosting the Checkmarx Web Portal component.


Various features in CxP-Tweaks.js require the script to be loaded within the Checkmarx Portal. This requires including the script within the Portal's .aspx and .html files via the following Script tags:

- <script type="text/javascript" src="/CxWebClient/CxP-Tweaks.js" defer></script>

Add the above script tag to the following files:
1. Checkmarx\Checkmarx Access Control\wwwroot\index.html
  - Required to enable the login page tweaks (removing Forgot Password, adding custom cuttons)
  - insert the script before the closing body tag at the end of the file
2. Checkmarx\CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx
  - Required for most of the remaining tweaks
  - insert the script before the closing header tag at the end of the file
3. Checkmarx\CheckmarxWebPortal\ScanQueryDescription.aspx
  - Required to hide the Codebashing box on the query description popup (accessed by clicking the '?' in the bottom-left vulnerability tree on the scan results viewer page)
  - insert the script before the closing body tag at the end of the file
4. Checkmarx\CheckmarxWebPortal\ViewerGrid.aspx
  - Required to show banners and to hide the codebashing button on the Results Viewer page
  - insert the script before the closing html tag at the end of the file
