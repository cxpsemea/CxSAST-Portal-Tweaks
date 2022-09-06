# Checkmarx Portal Tweaks

A set of customizations for the Checkmarx Portal, driven by JavaScript. This collection of tweaks includes:
1. Tweaks to the login page (removing the "Forgot Password" link, adding custom buttons)
2. Adding custom Banners / notifications for informing users of events, outages, or services (Onboarding/optimization)

## Deployment

The recommended method to deploy this script is:
- place the CxP-Tweaks.js file within the Checkmarx installation's WebPortal folder (by default: C:\Program Files\Checkmarx\CheckmarxWebPortal\Web\)
 - in a High-Availability or Distributed environment, CxP-Tweaks.js must be placed on every server hosting the Checkmarx Web Portal component.
- edit the CxP-Tweaks.js file to customize the settings for your environment.

## Enablement

Various features in CxP-Tweaks.js require the script to be loaded within the Checkmarx Portal. This requires including the script within the Portal's .aspx and .html files via the following Script tags:
	<script type="text/javascript" src="/CxWebClient/CxP-Tweaks.js" defer></script>

Add the above script tag to the following files:
1. Checkmarx\Checkmarx Access Control\wwwroot\index.html
 - Required to enable the login page tweaks (removing Forgot Password, adding custom cuttons)
2. Checkmarx\CheckmarxWebPortal\Web\UIComponents\UserControls\PortalMenu\PortalMenu.ascx
 - Required to enable the following tweaks:
  1. Changing the "Documentation & Services" link in the top-nav
  2. Hiding the "Codebashing" link in the top-nav
  3. Showing Banners within the Checkmarx Portal
  4. Individual page customizations on the Projects, ProjectState, AllScans, and Queue pages.
  5. Scheduler default time change.
3. Checkmarx\CheckmarxWebPortal\Web\ViewerMain.aspx
 - Required to enable the following:
  1. Showing Banners within the Results Viewer page
  2. Hiding the "Codebashing" link in the Results Viewer page
4. Checkmarx\CheckmarxWebPortal\Web\??



