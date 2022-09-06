/*
	CxP-Tweaks.js - https://github.com/michaelkubiaczyk/CxP-Tweaks
	Collection of tweaks for the Checkmarx Web Portal written by Michael Kubiaczyk / Checkmarx 
*/

	const CxPT = new Object();
	CxPT.loginpage = new Object();
	CxPT.menu = new Object();
	CxPT.banners = new Object();
	CxPT.topnav = new Object();
	CxPT.schedule = new Object();

///////////////////////////////////////////////////////////////////////////////////////////////////
//	Configuration options
//		Review and customize the items below depending on your environment needs.
	
// Login page options
	CxPT.loginpage.forgotpassword_enabled = 0; // 0 = hidden, 1 = visible
	CxPT.loginpage.custom_buttons = [ 
		[ "CxP-Tweaks", "https://github.com/michaelkubiaczyk/CxP-Tweaks" ], // example entry, uncomment to show
	];
	
// Banner options
	CxPT.banners.topnav_enabled = 1;
	CxPT.banners.resultsviewer_enabled = 1;
	CxPT.banners.topnav_banners = [
		"This is an example banner. <a href='https://github.com/michaelkubiaczyk/CxP-Tweaks' style='color: #5f5f5f; text-decoration: underline #333 solid !important' target='_blank'>Click here</a>" // example of usage, uncomment and enable to show
	];
	CxPT.banners.resultsviewer_banners = CxPT.banners.topnav_banners; // Show the same banners in all locations by default.

// Top-Nav button options	
	CxPT.topnav.codebashing_enabled = 0; 
	CxPT.topnav.support_enabled = 0; 
	CxPT.topnav.custom_buttons = [
		"<div id='CxPTMenuButton' onclick='CxPT.menu.Toggle()'><img src='app/cxSupport/images/support-icon.png'><br>CxP-Tweaks</div>"
	];
	
// Project Schedule options
	CxPT.schedule.enabled = 1; // if enabled, scheduled scan times will default to a random time between startHour and endHour, in increment minutes
	CxPT.schedule.startHour = 0; // midnight
	CxPT.schedule.endHour = 24; // midnight
	CxPT.schedule.increment = 15; // 15 minute increment
	
// Page-specific user-side tweaks
	CxPT.menu.page_items = [
		[ "ProjectState.aspx", "<a href='#' onclick='document.getElementById(\"ctl00_cpmain_ProjectStateGrid_GridData\").style.height = \"800px\"'>Table Height</a>" ],
		[ "Projects.aspx", "<a href='#' onclick='document.getElementById(\"ctl00_cpmain_ProjectsGrid_GridData\").style.height = \"800px\"'>Table Height</a>" ],
		[ "Scans.aspx", "<a href='#' onclick='document.getElementById(\"ctl00_cpmain_ScansGrid_GridData\").style.height = \"800px\"'>Table Height</a>" ],
		[ "UserQueue.aspx", "<a href='#' onclick='$find(\"ctl00_cpmain_QueueGrid\").get_masterTableView().rebind = function (){};'>Stop Refresh</a>" ],
		[ "UserQueue.aspx", "<a href='#' onclick='CxPT.menu.updateUserQueueHeight()'>Table Height</a>" ]
	];
	
///////////////////////////////////////////////////////////////////////////////////////////////////
// end configuration options
///////////////////////////////////////////////////////////////////////////////////////////////////



/*
	Actual code follows, do not change
*/

// Banners

	CxPT.banners.gridgap = 40; // height of the banner on the ViewerGrid page, in pixels.

	CxPT.banners.resultsviewer_Init = function () { // banner on the results viewer page
		if ( CxPT.banners.resultsviewer_enabled == 1 ) {
			//ID="dottomPane"
			//ID="mainSplitBar"
			var div = document.getElementById( "bottomSplitter" );
			if ( !div ) return;
			var span = CxPT.banners.createBanner();
			div.parentNode.insertBefore( span, div );
			CxPT.banners.setBannerText( CxPT.banners.resultsviewer_banners );
			
			/*
			var tree = document.getElementById( "RAD_SPLITTER_PANE_CONTENT_treePane" );
			alert( tree.style.cssText ); // the height changes due to the telerik framework, unclear how to override.
			*/
		}
	};
	CxPT.banners.topnav_Init = function () { // top nav
		if ( CxPT.banners.topnav_enabled == 1 ) {
			var div = document.getElementsByClassName ("breadcrumb");
			if ( div != 0 ) {
				var span = CxPT.banners.createBanner();
				div[0].parentNode.appendChild( span );		
				CxPT.banners.setBannerText( CxPT.banners.topnav_banners );	
			}
		}
	}
	CxPT.banners.getGridGap = function() {
		if ( CxPT.banners.resultsviewer.enabled  == 1 ) {
			return CxPT.banners.gridgap;
		}
		return 0;
	}

	CxPT.banners.setBannerText = function(banners) {
		if ( banners.length == 0 ) return;		
		var banner = document.getElementById('onboarding_banner');		
		var msg = Math.floor( Math.random() * banners.length );
		banner.innerHTML = banners[msg];
	}

	CxPT.banners.createBanner = function() {
		var span = document.createElement( "SPAN" );
		span.innerHTML = `<div style="background-color: #fff1cc;
					box-shadow: 0 3px 3px 0 rgba(0,0,0,.2);
					border-radius: 0;
					color: #5f5f5f;
					margin: 0;
					padding: .3rem 2.9rem;
					line-height: 1.9rem;
					clear: both;
					text-align: center;
					font-weight: normal">
		<span id='onboarding_banner'></span></div>`;
		return span;
	}

// Top Nav

	CxPT.topnav.Init = function() {
		if ( CxPT.topnav.codebashing_enabled == 0 || CxPT.topnav.support_enabled == 0 ) {
			var appsec = 0;
			var support = 0;
			
			var cb = document.getElementsByClassName( "pull-right menu-right-items-container" )[0];
			if ( cb != 0 ) {
				for ( var i = 0; i < cb.childNodes.length; i++ ) {
					if ( cb.childNodes[i].className == "app-sec-coach ribbon-container" ) {
						if ( cb.childNodes[i].innerHTML.includes( "app-sec-coach-button-for-ribbon" ) ) {
							appsec = cb.childNodes[i];
						} else if ( cb.childNodes[i].innerHTML.includes( "support-button-for-ribbon" ) ) {
							support = cb.childNodes[i];
						}						
					}
				}
								
				if ( appsec != 0 && CxPT.topnav.codebashing_enabled == 0 ) {
					if ( appsec.nextSibling.nodeType == 3 ) cb.removeChild( appsec.nextSibling );
					if ( appsec.nextSibling.nodeType == 1 && appsec.nextSibling.className == "right-menu-seperator" ) cb.removeChild( appsec.nextSibling );
					cb.removeChild( appsec );
				}
				if ( support != 0 && CxPT.topnav.support_enabled == 0 ) {
					if ( support.nextSibling.nodeType == 3 ) cb.removeChild( support.nextSibling );
					if ( support.nextSibling.nodeType == 1 && support.nextSibling.className == "right-menu-seperator" ) cb.removeChild( support.nextSibling );
					cb.removeChild( support );
				}
			}
		}
		
		
		if ( CxPT.topnav.custom_buttons.length > 0 ) {
			var cb = document.getElementsByClassName( "pull-right menu-right-items-container" )[0];
			if ( cb != 0 ) {
				for ( var i = 0; i < CxPT.topnav.custom_buttons.length; i++ ) {
					CxPT.topnav.addButton( cb, CxPT.topnav.custom_buttons[i] );
				}
			}
		}
	};
	
	CxPT.topnav.addButton = function(cb, button) {
		var new_div = document.createElement( "DIV" );
		new_div.className = "app-sec-coach ribbon-container";
		/*var new_button = document.createElement( "app-sec-coach-button-for-ribbon" );
		new_button.className = "app-sec-coach-button";
		new_div.appendChild( new_button );*/
		var sub_div = document.createElement( "DIV" );
		sub_div.className = "app-sec-coach-button ribbon";
		//new_button.appendChild( sub_div );
		new_div.appendChild( sub_div );
		sub_div.innerHTML = button;
		
			
		var separator_div = document.createElement( "DIV" );
		separator_div.className = "right-menu-seperator";
		
		cb.insertBefore( separator_div, cb.childNodes[0] );
		cb.insertBefore( new_div, cb.childNodes[0] );
		
		
		
        /*
			<app-sec-coach-button-for-ribbon class="app-sec-coach-button" link-data="linkData">
				<div class="app-sec-coach-button ribbon">
					<div ng-click="openLesson()">
						<img src="app/cxAcademy/images/app-sec-coach-icon.png"><br>Codebashing
					</div>
				</div>
			</app-sec-coach-button-for-ribbon>        
		*/
		
        
		
	};

// Login page

	CxPT.loginpage.addButton = function ( div, URL, text ) {
		div.innerHTML += "<div style='position: relative; top: 50px; left: 0px; right: 0px; bottom: 0px; height: 68px; overflow: none; margin-right: -17px; margin-bottom: -17px;'><a href='" + URL + "' class='cx-transparent__1fGE3' style='color: rgb(83, 200, 0); border-color: rgb(83, 200, 0); height: 40px; width: 325px; text-transform: initial; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: inline-block; padding-top: 5px; padding-left:0px; padding-right:0px;'>" + text + "</a></div>";
	}

	CxPT.loginpage.polling_counter = 0;

	CxPT.loginpage.polling_function = function () {
		console.debug( "Polling login page" );
		var links_div = document.getElementsByClassName('login-bottom-links_stac');
		var sso_div = document.getElementsByClassName('sso-login-seperator');
		
		if ( sso_div.length == 0 || links_div.length == 0 ) {
			CxPT.loginpage.polling_counter ++;
			if ( CxPT.loginpage.polling_counter < 20 ) {
				setTimeout(CxPT.loginpage.polling_function, 100);
			} else {
				console.debug( "Login page elements 'sso-login-seperator' and 'login-bottom-links_stac' were not created. You must have SSO (Domain or SAML) enabled." );
			}
		} else {
			
			if (CxPT.loginpage.forgotpassword_enabled == 0 && links_div != 0) links_div[0].innerHTML = ""; // remove the forgot password link
			
			if (CxPT.loginpage.custom_buttons.length > 0 && sso_div != 0) {
				var div = sso_div[0].nextSibling;
				CxPT.loginpage.custom_buttons.forEach( function (item) { CxPT.loginpage.addButton( div, item[1], item[0] ); } );
				//CxPT.loginpage.addButton( div, "https://lmgtfy.app/?q=how+to+use+checkmarx", "Help" );
			}
		}
	}
	
// Scheduler
	CxPT.schedule.Init = function() {
		//var original_ShcedulingChanged = ShcedulingChanged;
		//var new_function = ShcedulingChanged.toString().replace( '"12:00 AM"', 'CxPT.schedule.getRandomScheduledTime(i_object)' );
		//new_function = "ShcedulingChanged = " + new_function;
		//eval( new_function );
		
		if ( typeof enableChoosingSchedulingDaysAndTime != 'undefined' && typeof CxPT.schedule.originalSchedulerToggle == 'undefined' ) {
			CxPT.schedule.originalSchedulerToggle = enableChoosingSchedulingDaysAndTime;
			enableChoosingSchedulingDaysAndTime = function () {
				CxPT.schedule.originalSchedulerToggle();
				var timePicker = $find("ctl00_cpmain_TimeInput");
				timePicker.get_dateInput().set_value( CxPT.schedule.getRandomScheduledTime(false) );
			};
		}
		
		var datepicker = $find( "ctl00_cpmain_TimeInput_dateInput" );
		if ( datepicker ) {
			datepicker.set_displayValue( CxPT.schedule.getRandomScheduledTime(true) );
		}
		
	}
	
	CxPT.schedule.getRandomScheduledTime = function ( b24 ) {
		var slots = (CxPT.schedule.endHour - CxPT.schedule.startHour) * 60 / CxPT.schedule.increment;
		
		var slot = Math.floor( Math.random() * slots );
		var slotTime = slot * CxPT.schedule.increment / 60;
		
		var hour = CxPT.schedule.startHour + Math.floor( slotTime );
		var min = (slotTime - Math.floor( slotTime ))*60;
		
		if ( b24 ) {
			if ( min == 0 )
				min = "00";
			else 
				if ( min < 10 ) min = "0"+min;
			
			if ( hour == 0 ) return "00:" + min;
			if ( hour < 10 ) return "0" + hour + ":" + min;
			return hour + ":" + min;
		} else {
			if ( min == 0 ) 
				min = "00";
			else 
				if ( min < 10 ) min = "0" + min;
			
			var suffix = "AM";
			if ( hour >= 12 ) {
				hour -= 12;
				suffix = "PM";
			}
			
			if ( hour == 0 ) 
				hour = "00";
			else 
				if ( hour < 10 ) hour = "0" + hour;
			return "'" + hour + ":" + min + suffix;
		}
	}
	
	

// Menu items per page
	CxPT.menu.Toggle = function () {
		if ( typeof CxPT.menu.obj == 'undefined' ) {
			CxPT.menu.Init();
			if ( CxPT.menu.obj.childNodes.length == 0 ) {
				CxPT.menu.addItem( "<a href='#'>No tweaks on this page</a>" );
			}
		} else {
			if ( CxPT.menu.obj.style.display == "block" ) 
				CxPT.menu.obj.style.display = "none";
			else	
				CxPT.menu.obj.style.display = "block";
		}
	}
	
	CxPT.menu.Init = function () {
		var div = document.getElementById( 'CxPTMenuButton' );
		if ( !div ) return;
			
		var UL = document.createElement( "UL" );
		UL.style.cssText = "position:absolute; background-color: #baabaa; padding: 2px; border: 1px solid black; display: block; min-width:100px; text-align:left; list-style-type:none; margin:2px;"
		div.appendChild( UL );
		CxPT.menu.obj = UL;
		
		if ( CxPT.menu.page_items.length > 0 ) {
			for ( var i = 0; i < CxPT.menu.page_items.length; i++ ) {
				if ( window.location.pathname.includes( CxPT.menu.page_items[i][0] ) ) {
						CxPT.menu.addItem( CxPT.menu.page_items[i][1] );
				}
			}
		}
	}

	CxPT.menu.addItem = function ( entry ) {
		var LI = document.createElement( "LI" );
//		LI.style.cssText = "margin: 0px;";
		LI.innerHTML = entry;
		CxPT.menu.obj.appendChild( LI );
	}


	CxPT.menu.updateUserQueueHeight = function () {
		document.getElementById("ctl00_cpmain_QueueGrid_GridData").style.height = "800px"; 
		var MTV = $find("ctl00_cpmain_QueueGrid").get_masterTableView();
		
		if ( typeof MTV.originalUserQueueRebind == 'undefined' ) {
			
			MTV.originalUserQueueRebind = MTV.rebind;
			MTV.rebind = function () {
				MTV.originalUserQueueRebind();
				setTimeout( CxPT.menu.queueRefreshReset, 100 );
			};
		}
	}
	
	CxPT.menu.queueRefreshReset = function () {
		var grid = document.getElementById("ctl00_cpmain_QueueGrid_GridData");
		if ( !grid ) return;
		
		if ( typeof grid.originalUserQueueRebind == 'undefined' ) {
			CxPT.menu.updateUserQueueHeight();
		}		
	}
		

CxPT.Init = function () {
	console.debug( "Initializing Checkmarx Portal Tweaks" );
	
	topnav_present = 1;
	
	
	if ( window.location.pathname.includes( "/auth/" ) ) {
		if ( CxPT.loginpage.forgotpassword_enabled == 0 || CxPT.loginpage.custom_buttons.length > 0 ) CxPT.loginpage.polling_function();
		topnav_present = 0;
	} else if ( window.location.pathname.includes( "/ViewerMain" ) ) {
		if ( CxPT.banners.resultsviewer_banners.length > 0 ) CxPT.banners.resultsviewer_Init();
		topnav_present = 0;
	} else if ( window.location.pathname.includes( "/Projects.aspx" ) ) {
		if ( CxPT.schedule.enabled == 1 ) CxPT.schedule.Init();
	}

	if ( topnav_present ) {
		if ( CxPT.banners.topnav_banners.length > 0 ) CxPT.banners.topnav_Init();
		CxPT.topnav.Init();
		
		// if ( CxPT.schedule.enabled == 1 ) CxPT.schedule.Init(); // in progress work to add this to New Projects also.
	}

}

CxPT.Init();


