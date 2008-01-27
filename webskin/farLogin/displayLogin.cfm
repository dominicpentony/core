<cfsetting enablecfoutputonly="Yes">
<!--- @@displayname: Farcry UD login form --->

<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" />
<cfimport taglib="/farcry/core/tags/security/" prefix="sec" />

<cfoutput>
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml">
	<head> 
		<title>#application.config.general.siteTitle# :: #application.applicationname#</title>
</cfoutput>

<!--- check for custom Admin CSS in project codebase --->
<cfif fileExists("#application.path.project#/www/css/customadmin/admin.css")>
    <cfoutput>
    	<link href="#application.url.webroot#/css/customadmin/admin.css" rel="stylesheet" type="text/css">
    </cfoutput>
<cfelse>
    <cfoutput>
    	<link href="#application.url.farcry#/css/main.css" rel="stylesheet" type="text/css">
    </cfoutput>
</cfif>

<cfoutput>
	</head>
	
	<body id="sec-login">
</cfoutput>
		
<ft:form css="forms.css" class="login">

<cfoutput>
	<div id="login">
		
		<h1>
			<a href="#application.url.webroot#/">
</cfoutput>

<!--- if there is a site logo, use it instead of the default placeholder --->       
<cfif structKeyExists(application.config.general,'siteLogoPath') and application.config.general.siteLogoPath NEQ "">
	<cfoutput>
		<img src="#application.config.general.siteLogoPath#" alt="#application.config.general.siteTitle#" />
	</cfoutput>
<cfelse>
	<cfoutput>
		<img src="images/logo_placeholder.gif" alt="#application.config.general.siteTitle#" />
	</cfoutput>
</cfif>

<cfoutput>
			</a>
			#application.config.general.siteTitle#
			<span>#application.config.general.siteTagLine#</span>

		</h1>

</cfoutput>
		
		<ft:form>
			<cfif structKeyExists(server, "stFarcryProjects") AND listLen(structKeyList(server.stFarcryProjects)) GT 1>
				<cfoutput><fieldset class="formSection"></cfoutput>
				
				<cfoutput>
					<select id="selectFarcryProject" onchange="window.location='#application.url.webtop#/login.cfm?returnUrl=#urlencodedformat(url.returnUrl)#&farcryProject='+this.value;">						
						<cfloop list="#structKeyList(server.stFarcryProjects)#" index="thisProject">
							<option value="#thisProject#"<cfif cookie.currentFarcryProject eq thisProject> selected</cfif>>LOGIN TO: #server.stFarcryProjects[thisProject]#</option>
						</cfloop>						
					</select>
				</cfoutput>

				
				<cfoutput></fieldset></cfoutput>		
			</cfif>
			
		
			<sec:SelectUDLogin />
			

			
			
			<ft:object typename="farLogin" />


			<cfoutput><fieldset class="formSection"></cfoutput>
			

				<cfif isdefined("arguments.stParam.message") and len(arguments.stParam.message)>
					<cfoutput>
						<div class="error">#arguments.stParam.message#</div>
					</cfoutput>
				</cfif>
			
				<ft:farcrybutton value="Log In" />
			<cfoutput></fieldset></cfoutput>
		</ft:form>

<cfoutput>

		<h3><img src="images/powered_by_farcry_watermark.gif" />Tell it to someone who cares</h3>

	</div>
	
</cfoutput>
	
</ft:form>

<cfoutput>
	</body>
</html>
</cfoutput>