<cfcomponent displayName="Security Scope" hint="Encapsulates the generic higher-level security functions and variables" output="false" scopelocation="application.security">

	<cfimport taglib="/farcry/core/tags/farcry" prefix="farcry" />
	
	
	<cffunction name="init" access="public" output="false" returntype="any" hint="Initialises and returns the security scope component">
		<cfset var permission = "" /><!--- Used in deprecated code --->
		<cfset var stPermission = structnew() /><!--- Used in deprecated code --->
		<cfset var i = 0 /><!--- Used in deprecated code --->
		
		<cfset initCache() />
		
		<!--- THE FOLLOWING VARIABLES ARE DEPRECATED --->
		<!--- THIS CODE SHOULD BE BURNT IN A FIRE AND SCATTERED OVER MOVING WATER --->
		<cfset application.factory.oAuthorisation = createObject("component","#application.securitypackagepath#.authorisation") />
		<cfset application.factory.oAuthentication = createObject("component","#application.securitypackagepath#.authentication") />
		
		<cfset application.dmSec.lDefaultPolicyGroups = this.factory.role.getDefaultRoles() />
		
		<cfloop list="#this.factory.permission.getAllPermissions()#" index="permission">
			<cfset stPermission = this.factory.permission.getData(objectid=permission,bUseInstanceCache=false) />
			<cfif arraylen(stPermission.aRelatedtypes)>
				<cfloop from="1" to="#arraylen(stPermission.aRelatedtypes)#" index="i">
					<cfparam name="application.permission.#stPermission.aRelatedtypes[i]#" default="#structnew()#" />
					<cfset application.permission[stPermission.aRelatedtypes[i]][stPermission.title] = structnew() />
					<cfset application.permission[stPermission.aRelatedtypes[i]][stPermission.title].permissionID = stPermission.objectid />
					<cfset application.permission[stPermission.aRelatedtypes[i]][stPermission.title].permissionName = stPermission.title />
					<cfset application.permission[stPermission.aRelatedtypes[i]][stPermission.title].permissionNotes = "" />
					<cfset application.permission[stPermission.aRelatedtypes[i]][stPermission.title].permissionType = stPermission.aRelatedtypes[i] />
				</cfloop>
			<cfelse>
				<cfparam name="application.permission.PolicyGroup" default="#structnew()#" />
				<cfset application.permission.PolicyGroup[stPermission.title] = structnew() />
				<cfset application.permission.PolicyGroup[stPermission.title].permissionID = stPermission.objectid />
				<cfset application.permission.PolicyGroup[stPermission.title].permissionName = stPermission.title />
				<cfset application.permission.PolicyGroup[stPermission.title].permissionNotes = "" />
				<cfset application.permission.PolicyGroup[stPermission.title].permissionType = "PolicyGroup" />
			</cfif>
		</cfloop>
		
		<cfreturn this />
	</cffunction>

	<cffunction name="initCache" access="public" output="false" returntype="void" hint="Initialises the security cache">
		<cfset var comp = "" />
		
		<!--- Cache --->
		<cfset this.stPermissions = structNew() />
		<cfset this.cache = structnew() />
		<cfset this.cache.roles = structnew() />
		<cfset this.cache.permissionlookup = structnew() />
		<cfset this.cache.rolelookup = structnew() />
		
		<!--- Factory --->
		<cfset this.factory.role = createObject("component", application.factory.oUtils.getPath("types","farRole")) />
		<cfset this.factory.permission = createObject("component", application.factory.oUtils.getPath("types","farPermission")) />
		<cfset this.factory.barnacle = createObject("component", application.factory.oUtils.getPath("types","farBarnacle")) />
		
		<!--- User directories --->
		<cfset this.userdirectories = structnew() />
		<cfset this.userdirectoryorder = "" />
		
		<cfloop list="#application.factory.oUtils.getComponents('security')#" index="comp">
			<cfif comp neq "UserDirectory" and application.factory.oUtils.extends(application.factory.oUtils.getPath("security",comp),"farcry.core.packages.security.UserDirectory")>
				<cfset ud = createobject("component",application.factory.oUtils.getPath("security",comp)).init() />
				<cfset this.userdirectories[ud.key] = ud />
				<cfset this.userdirectoryorder = listappend(this.userdirectoryorder,ud.key) />
			</cfif>
		</cfloop>
		
		<cfset this.cache.defaultroles = this.factory.role.getDefaultRoles() />
	</cffunction>

	<cffunction name="onRequestStart" access="public" output="false" returntype="void" hint="This function should be executed on page request start">

		<!--- These variables are depreciated --->
		<cfset request.dmSec.oAuthorisation = createObject("component","#application.securitypackagepath#.authorisation") />
		<cfset request.dmSec.oAuthentication = createObject("component","#application.securitypackagepath#.authentication") />
	</cffunction>


	<!--- Current user queries --->
	<cffunction name="getCurrentUserID" access="public" output="false" returntype="string" hint="Returns the id of the current user" bDocument="true">
		<cfif isdefined("session.security.userid")>
			<cfreturn session.security.userid />
		<cfelse>
			<cfreturn "" />
		</cfif>
	</cffunction>


	<!--- Current user queries --->
	<cffunction name="isLoggedIn" access="public" output="false" returntype="boolean" hint="Returns true if a user has logged in." bDocument="true">
		<cfif len(getCurrentUserID())>
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="checkPermission" access="public" output="true" returntype="boolean" hint="Returns true if a user has the specified permission" bDocument="true">
		<cfargument name="permission" type="string" required="false" default="" hint="The permission to check" />
		<cfargument name="object" type="string" required="false" default="" hint="If specified, will check barnacle" />
		<cfargument name="role" type="string" required="false" default="" hint="List of roles to check" />
		<cfargument name="type" type="string" required="false" default="" hint="The type for the webskin to check" />
		<cfargument name="webskin" type="string" required="false" default="" hint="The webskin or permission set to check" />
				
		<cfset var hashKey = "" />
		<cfset var result = -1 />
		<cfset var oType = "" />
		<cfset var navID = "" />
		
		<!--- If the role was left empty, use current user's roles --->
		<cfif not len(arguments.role)>
			<cfset arguments.role = getCurrentRoles() />
		</cfif>
		
			
		<!--- RETURN THE CACHE IF ALREADY PROCESSED. --->
		<cfset hashKey = hash("#arguments.permission#-#arguments.object#-#arguments.role#-#arguments.type#-#arguments.webskin#") />
		<cfif structKeyExists(this.stPermissions, "#hashKey#")>
			<cfreturn this.stPermissions[hashKey] />
		</cfif>
		
		<!--------------------------------------------------------------------------------------------------- 
		IF WE MAKE IT TO HERE, WE NEED TO DETERMINE THE PERMISSION AND THEN STORE IT IN THE APPLICATION CACHE.
		 --------------------------------------------------------------------------------------------------->
		
		<cfif len(arguments.type) and len(arguments.webskin)>
		
			<cfset result = this.factory.role.checkWebskin(role=arguments.role,type=arguments.type,webskin=arguments.webskin) />
			
		<cfelseif len(arguments.type) and len(arguments.permission)>
		
			<!--- Aliasing of typename to permission name for backward compatibility --->
			<cfswitch expression="#arguments.type#">
				<cfcase value="dmNews">
					<cfset arguments.type = "News" />
				</cfcase>
				<cfcase value="dmFacts">
					<cfset arguments.type = "Fact" />
				</cfcase>
				<cfcase value="dmEvent">
					<cfset arguments.type = "Event" />
				</cfcase>
				<cfcase value="dmLink">
					<cfset arguments.type = "Link" />
				</cfcase>
			</cfswitch>
		
			<cfif this.factory.permission.permissionExists("#arguments.type##arguments.permission#")>
				<cfset result = this.factory.role.getRight(role=arguments.role, permission=this.factory.permission.getID("#arguments.type##arguments.permission#")) />
			<cfelseif this.factory.permission.permissionExists("generic#arguments.permission#")>
				<cfset result = this.factory.role.getRight(role=arguments.role, permission=this.factory.permission.getID("generic#arguments.permission#")) />
			<cfelse>
				<!--- This should only happen for checks to object permissions that don't have corresponding type permissions --->
				<cfset result = 1 />
			</cfif>
		
		<cfelseif len(arguments.permission)>
		
			<!--- If the permission was specified by name, retrieve the objectid --->
			<cfif not isvalid("uuid",arguments.permission)>
				<cfset arguments.permission = this.factory.permission.getID(arguments.permission) />
				<cfif not len(arguments.permission)>
					<cfset result = 0 />
				</cfif>
			</cfif>
			
			<cfif result LT 0>
				<!--- If an object was provided check the barnacle for that object, otherwise check the basic permission --->
				<cfif isvalid("uuid",arguments.object)>
				
					
					<cfif not len(arguments.type) or not structKeyExists(application.stCoapi, arguments.type)>
						<cfset arguments.type = application.fapi.findType(arguments.object) />
					</cfif>
					
					<cfif arguments.type EQ "dmNavigation">
						<cfset result = 1 /><!--- permission check on dmNavigation is handled below. --->
					<cfelse>
						<cfset result = this.factory.barnacle.checkPermission(object=arguments.object,permission=arguments.permission,role=arguments.role) />
					</cfif>
					
					<!--- Also check the permission on the parent nav node --->
					<cfif len(arguments.type) AND structKeyExists(application.stCOAPI[arguments.type], "bUseInTree") AND application.stCOAPI[arguments.type].bUseInTree>
						<cfset oType = application.fapi.getContentType(arguments.type) />
						<cfset navID = oType.getNavID(objectid=arguments.object,typename=arguments.type) />	
						<cfset result = result and (not len(navID) or this.factory.barnacle.checkPermission(object=navID,permission=arguments.permission,role=arguments.role)) />
						
					</cfif>
				<cfelse>
					<cfset result = this.factory.role.getRight(role=arguments.role,permission=arguments.permission) />
				</cfif>
			</cfif>
		<cfelse>
		
			<cfthrow message="Either a webskin or a permission are required for checkPermission" />
			
		</cfif>
		
		<cfset this.stPermissions[hashKey] = result />
		
		<cfreturn this.stPermissions[hashKey] />
		
	</cffunction>

	<cffunction name="getCurrentRoles" access="public" output="true" returntype="string" hint="Returns the roles of the current logged in user" bDocument="true">
		<cfif isdefined("session.security.roles")>
			<cfreturn application.factory.oUtils.listMerge(this.cache.defaultroles,session.security.roles) />
		<cfelse>
			<cfreturn this.cache.defaultroles />
		</cfif>
	</cffunction>
	
	<cffunction name="getCurrentUD" access="public" output="false" returntype="string" hint="Returns the UD of the current user" bDocument="true">
		<cfif isdefined("session.security.userid")>
			<cfreturn listlast(session.security.userid,"_") />
		<cfelse>
			<cfreturn "" />
		</cfif>		
	</cffunction>
	
	<cffunction name="hasRole" returntype="boolean" output="false" access="public" hint="Returns true if the current user has the specified role">
		<cfargument name="role" type="string" required="false" default="" hint="Roles to check" />
		
		<cfif isvalid("uuid",arguments.role)>
			<cfreturn listcontainsnocase(getCurrentRoles(),arguments.role) />
		<cfelse>
			<cfreturn listcontainsnocase(getCurrentRoles(),this.factory.role.getID(arguments.role)) />
		</cfif>
	</cffunction>
	

	<!--- User Directory functions --->
	<cffunction name="getAllUD" access="public" output="false" returntype="string" hint="Returns a list of the user directories this application supports">
		<cfset var lUD = "" />
		<cfset var thisUD = "" />
		
		<cfloop list="#this.userdirectoryorder#" index="thisud">
			<cfif this.userdirectories[thisud].isEnabled()>
				<cfset lUD = listappend(lUD,thisud) />
			</cfif>
		</cfloop>
		
		<cfreturn lUD />
	</cffunction>
	
	<cffunction name="getDefaultUD" access="public" output="false" returntype="string" hint="Returns the default user directory for this application">
		<cfset var result = "" />
		
		<cfif structKeyExists(url, "ud")>
			<cfset result = url.ud />
		<cfelse>			
			<cfif isdefined("application.config.general.defaultUserDirectory") and len(application.config.general.defaultUserDirectory)>
				<cfset result = application.config.general.defaultUserDirectory />
			<cfelse>
				<cfset result = listfirst(getAllUD()) />
			</cfif>
		</cfif>

		<cfreturn result />
		
	</cffunction>
	
	<cffunction name="getGroupUsers" access="public" returntype="array" description="Returns an array of the members of the specified groups" output="false" bDocument="true">
		<cfargument name="groups" type="any" required="true" hint="The list or array of groups" />
		
		<cfset var i = 0 />
		<cfset var j = 0 />
		<cfset var aResult = arraynew(1) />
		<cfset var ud = "" />
		<cfset var group = "" />
		<cfset var aUsers = arraynew(1) />
		<cfset var user = "" />
		
		<cfif not isarray(arguments.groups)>
			<cfset arguments.groups = listtoarray(arguments.groups) />
		</cfif>
		
		<cfif arraylen(arguments.groups)>
			<cfloop from="1" to="#arraylen(arguments.groups)#" index="i">
				<cfset ud = listlast(arguments.groups[i],"_") />
				<cfset group = listfirst(arguments.groups[i],"_") />
				<cfif structkeyexists(this.userdirectories,ud)>
					<cfset aUsers = this.userdirectories[ud].getGroupUsers(group=group) />
					<cfif arraylen(aUsers)>
						<cfloop from="1" to="#arraylen(aUsers)#" index="j">
							<cfset arrayappend(aResult,"#aUsers[j]#_#ud#") />
						</cfloop>
					</cfif>
				</cfif>
			</cfloop>
		</cfif>

		<cfreturn aResult />
	</cffunction>
	
	<cffunction name="getLoginForm" access="public" output="false" returntype="string" hint="Returns the name of the login form component for the specified user directory">
		<cfargument name="ud" type="string" required="true" hint="The user directory to query" />
		
		<cfreturn this.userdirectories[arguments.ud].getLoginForm() />
	</cffunction>

	<cffunction name="processLogin" access="public" output="false" returntype="struct" hint="Attempts to authenticate a login and if unsuccessful, sets up any subsequent login forms for the page. Returns a struct containing all the nessesary information for a user directories login form.">

		<!--- Attempt to Authenticate the current form post if one has been submitted. --->
		<cfset var stResult = authenticate() />
		
		<!--- Setup Default return structure --->
		<cfparam name="stResult.authenticated" default="false" /><!--- Did the user successfully login --->
		<cfparam name="stResult.message" default="" /><!--- Any message that the user directory may have returned --->
		<cfparam name="stResult.loginReturnURL" default="#session.loginReturnURL#" /><!--- The return url after a successful login --->
		
		<!--- WHICH USERDIRECTORY SHOULD WE BE RENDERING THE FORM FOR --->
		<cfset stResult.ud = getDefaultUD() />
		
		<!--- Allow for custom message --->
		<cfif structKeyExists(session.fc, "loginMessage") AND len(session.fc.loginMessage) AND NOT len(stResult.message)>
			<cfset stResult.message = session.fc.loginMessage />
			<cfset structDelete(session.fc, "loginMessage") />
		</cfif>
		
		<!--- DETERMINE THE FORM TYPENAME FOR THE CURRENT USER DIRECTORY SELECTED ABOVE --->
		<cfset stResult.loginTypename = application.security.getLoginForm(stResult.ud) />
		<cfset stResult.loginWebskin = "displayLogin" /><!--- Default login webskin to displayLogin --->
		
		<cfif findNoCase(application.url.webtop, stResult.loginReturnURL)>
			<!--- LOGGING INTO THE WEBTOP --->
			<cfif application.fapi.hasWebskin(stResult.loginTypename,"displayPageLoginWebtop")>
				<cfset stResult.loginWebskin = "displayPageLoginWebtop" />
			</cfif>
		<cfelse>
			<!--- LOGGING INTO THE PROJECTS SITE --->
			<cfif application.fapi.hasWebskin(stResult.loginTypename,"displayPageLoginProject")>
				<cfset stResult.loginWebskin = "displayPageLoginProject" />
			</cfif>
		</cfif>	
		
		<!--- IF WE ARE NOT AUTHENTICATED --->
		<cfif not stResult.authenticated>

			<!--- LOOK FOR ANY FRAMEWORK SPECIFIC ERROR LOGIC --->
			<cfif structKeyExists(url, "error") and not len(stResult.message)>
				<cfif url.error eq "draft">
					<!--- TODO: i18n --->
					<cfset stResult.authenticated = false />
				    <cfset stResult.message = "This page is in draft. You are required to login." />
				</cfif>
				<cfif url.error eq "restricted">
					<!--- TODO: i18n --->
					<cfset stResult.authenticated = false />
				    <cfset stResult.message = "You have attempted to access a restricted area of the site that you do not have permission to view. You are required to login." />
				</cfif>
			</cfif>
			
			<!--- ARE WE LOGGING IN BECAUSE WE JUST LOGGED OUT? --->
			<cfif session.loginReturnURL contains "logout=1">
				<cfset application.security.logout() />
				<cfset stResult.authenticated = false />
			    <cfset stResult.message = "You have successfully logged out." />
			</cfif>		
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
	

	<cffunction name="authenticate" access="public" output="true" returntype="struct" hint="Attempts to authenticate a user using each directory, and returns true if successful">
		<cfset var ud = "" />
		<cfset var stResult = structnew() />
		<cfset var udlist = structsort(this.userdirectories,"numeric","asc","seq") />
		
		<cfimport taglib="/farcry/core/tags/farcry/" prefix="farcry" />
		
		<cfif isArray(udlist)>
			<cfset udlist = arrayToList(udlist) />
		</cfif>
		
		<cfloop list="#udlist#" index="ud">
			<!--- Authenticate user --->
			<cfset stResult = this.userdirectories[ud].authenticate(argumentCollection="#arguments#") />
			
			<cfif structkeyexists(stResult,"authenticated")>
				<!--- This allows your userdirectory check multiple user directories and pass back the successfull one. --->
				<cfparam name="stResult.UD" default="#ud#" />
				
				<cfif not stResult.authenticated>
					<farcry:logevent type="security" event="loginfailed" userid="#stResult.userid#_#stResult.UD#" notes="#stResult.message#" />
					<cfbreak />
				</cfif>
				
				<!--- SUCCESS - log in user --->
				<cfset login(userid=stResult.userid,ud=stResult.UD) />
				
				<!--- Return 'success' --->
				<cfbreak />
			</cfif>
		</cfloop>
		
		<!--- Returning an empty struct indicates that no authentication attempt was detected --->
		<cfreturn stResult />
	</cffunction>

	<cffunction name="login" access="public" returntype="void" description="Logs in the specified user" output="false">
		<cfargument name="userid" type="string" required="true" hint="The UD specific user id" />
		<cfargument name="ud" type="string" required="true" hint="The user directory" />
		
		<cfset var groups = "" />
		<cfset var aUserGroups = arraynew(1) />
		<cfset var i = 0 />
		<cfset var oProfile = createObject("component", application.stcoapi["dmProfile"].packagePath) />
		<cfset var stDefaultProfile = structnew() />
		
		<!--- Get user groups and convert them to Farcry roles --->
		<cfset aUserGroups = this.userdirectories[arguments.ud].getUserGroups(arguments.userid) />
		<cfloop from="1" to="#arraylen(aUserGroups)#" index="i">
			<cfset groups = listappend(groups,"#aUserGroups[i]#_#arguments.ud#") />
		</cfloop>
		<cfset session.dmSec.authentication.lPolicyGroupIds = this.factory.role.groupsToRoles(groups) />
		
		<!--- New structure --->
		<cfset session.security.userid = "#arguments.userid#_#arguments.ud#" />
		<cfset session.security.roles = this.factory.role.groupsToRoles(groups) />
		
		<!--- Get users profile --->
		<cfset session.dmProfile = oProfile.getProfile(userName=arguments.userid,ud=arguments.ud) />
		<cfset stDefaultProfile = this.userdirectories[arguments.ud].getProfile(arguments.userid,duplicate(session.dmProfile)) />
		<cfparam name="stDefaultProfile.override" default="false" />
		<cfif not session.dmProfile.bInDB>
			<cfset structappend(session.dmProfile,stDefaultProfile,stDefaultProfile.override) />

			<cfset session.dmProfile.userdirectory = arguments.ud />
			<cfset session.dmProfile.username = "#arguments.userid#_#arguments.ud#" />
			<cfset session.dmprofile = oProfile.createProfile(session.dmprofile) />
			
			<!--- Go and get it again now its in the db --->
			<cfset stDefaultProfile = this.userdirectories[arguments.ud].getProfile(userid=arguments.userid,stCurrentProfile=session.dmProfile) />
			<cfparam name="stDefaultProfile.override" default="false" />
			<cfset structappend(session.dmProfile,stDefaultProfile,stDefaultProfile.override) />
			<cfset oProfile.setData(stProperties=session.dmProfile) />
		<cfelseif stDefaultProfile.override>
			<cfset structappend(session.dmProfile,stDefaultProfile,true) />
			<cfset oProfile.setData(stProperties=session.dmProfile) />
		</cfif>
	
		<!--- i18n: find out this locale's writing system direction using our special psychic powers --->
        <cfif application.i18nUtils.isBIDI(session.dmProfile.locale)>
            <cfset session.writingDir = "rtl" />
        <cfelse>
            <cfset session.writingDir = "ltr" />
        </cfif>
		
        <!--- i18n: final bit, grab user language from locale, tarts up html tag --->
        <cfset session.userLanguage = left(session.dmProfile.locale,2) />
		
		<!--- DEPRECATED - THESE VARIABLES SHOULD NOT BE USED --->
		<!--- Retrieve user info --->
		<cfif ud eq "CLIENTUD">
			<cfset session.dmSec.authentication = createObject("component", application.stcoapi["farUser"].packagePath).getByUserID(arguments.userid) />
			<cfif structkeyexists(session.dmSec.authentication,"password")>
				<cfset structdelete(session.dmSec.authentication,"password") />
			</cfif>
		</cfif>
		<cfset session.dmSec.authentication.userlogin = arguments.userid />
		<cfset session.dmSec.authentication.canonicalname = "#arguments.userid#_#arguments.ud#" />
		<cfset session.dmSec.authentication.userdirectory = arguments.ud />
		
		<!--- Admin flag --->
		<cfset session.dmSec.authentication.bAdmin = checkPermission(permission="Admin") />
		
		<!--- /DEPRECATED --->
		
		<!--- First login flag --->
		<cfif createObject("component", application.stcoapi["farLog"].packagePath).filterLog(userid=session.security.userid,type="security",event="login").recordcount>
			<cfset session.security.firstlogin = false />
			
			<!--- DEPRECATED --->
			<cfset session.firstLogin = false />
		<cfelse>
			<cfset session.security.firstlogin = true />
			
			<!--- DEPRECATED --->
			<cfset session.firstlogin = true />
		</cfif>
		
		<!--- Log the result --->
		<cfif session.firstLogin>
			<farcry:logevent type="security" event="login" userid="#session.security.userid#" notes="First login" />
		<cfelse>
			<farcry:logevent type="security" event="login" userid="#session.security.userid#" />
		</cfif>
	</cffunction>

	<cffunction name="logout" access="public" output="false" returntype="void" hint="" bDocument="true">
		<cfset structdelete(session,"security") />
		<cfset structdelete(session,"dmProfile") />
		
		<!--- DEPRECIATED VARIABLE --->
		<cfset structdelete(session,"dmSec") />
		
		<!--- Security has changed so we need to re-initialise our request.mode struct --->
		<cfset initRequestMode() />
	</cffunction>
	
	


	<!--- CACHE FUNCTIONS - SHOULD ONLY BE ACCESSED BY CORE CODE --->
	<cffunction name="setCache" access="public" output="false" returntype="boolean" hint="Sets up the ermission cache structure">
		<cfargument name="role" type="uuid" required="true" hint="The role to cache" />
		<cfargument name="permission" type="uuid" required="false" hint="The permission to cache" />
		<cfargument name="object" type="string" required="false" default="" hint="The object to cache" />
		<cfargument name="webskin" type="string" required="false" default="" hint="The webskin to cache" />
		<cfargument name="right" type="numeric" required="true" hint="The right value to cache" />
		
		<cfif not structkeyexists(this.cache.roles,arguments.role)>
			<cfset this.cache.roles[arguments.role] = structnew() />
		</cfif>
		<cfif not structkeyexists(this.cache.roles[arguments.role],"permissions")>
			<cfset this.cache.roles[arguments.role].permissions = structnew() />
		</cfif>
		<cfif not structkeyexists(this.cache.roles[arguments.role],"barnacles")>
			<cfset this.cache.roles[arguments.role].barnacles = structnew() />
		</cfif>
		<cfif not structkeyexists(this.cache.roles[arguments.role],"webskins")>
			<cfset this.cache.roles[arguments.role].webskins = structnew() />
		</cfif>
		
		<cfif isvalid("uuid",arguments.object) and isvalid("uuid",arguments.permission)>
			<cfset this.cache.roles[arguments.role].barnacles[arguments.object][arguments.permission] = arguments.right />
		<cfelseif len(arguments.webskin)>
			<cfset this.cache.roles[arguments.role].webskins[arguments.webskin] = arguments.right />
		<cfelseif isvalid("uuid",arguments.permission)>
			<cfset this.cache.roles[arguments.role].permissions[arguments.permission] = arguments.right />
		<cfelse>
			<cfthrow message="setCache requires the permission or webskin argument" />
		</cfif>
		
		<cfreturn arguments.right />
	</cffunction>

	<cffunction name="isCached" access="public" output="false" returntype="boolean" hint="Returns true if the right is cached">
		<cfargument name="role" type="uuid" required="true" hint="The role to find" />
		<cfargument name="permission" type="uuid" required="false" hint="The permission to find" />
		<cfargument name="object" type="string" required="false" default="" hint="The object to find" />
		<cfargument name="webskin" type="string" required="false" default="" hint="The webskin to cache" />
		
		<cfif isvalid("uuid",arguments.object) and isvalid("uuid",arguments.permission)>
			<cfreturn structkeyexists(this.cache.roles,arguments.role) and structkeyexists(this.cache.roles[arguments.role],"barnacles") and structkeyexists(this.cache.roles[arguments.role].barnacles,arguments.object) and structkeyexists(this.cache.roles[arguments.role].barnacles[arguments.object],arguments.permission) />
		<cfelseif len(arguments.webskin)>
			<cfreturn structkeyexists(this.cache.roles,arguments.role) and structkeyexists(this.cache.roles[arguments.role],"webskins") and structkeyexists(this.cache.roles[arguments.role].webskins,arguments.webskin) />
		<cfelseif isvalid("uuid",arguments.permission)>
			<cfreturn structkeyexists(this.cache.roles,arguments.role) and structkeyexists(this.cache.roles[arguments.role],"permissions") and structkeyexists(this.cache.roles[arguments.role].permissions,arguments.permission) />
		<cfelse>
			<cfthrow message="isCached requires the permission or webskin argument" />
		</cfif>
	</cffunction>
	
	<cffunction name="getCache" access="public" output="false" returntype="boolean" hint="Returns the cached right. Doesn't error check.">
		<cfargument name="role" type="uuid" required="true" hint="The role to retrieve" />
		<cfargument name="permission" type="uuid" required="false" hint="The permission to retrieve" />
		<cfargument name="object" type="string" required="false" default="" hint="The object to retrieve" />
		<cfargument name="webskin" type="string" required="false" default="" hint="The webskin to cache" />
		
		<cfif isvalid("uuid",arguments.object) and isvalid("uuid",arguments.permission)>
			<cfreturn this.cache.roles[arguments.role].barnacles[arguments.object][arguments.permission] />
		<cfelseif len(arguments.webskin)>
			<cfreturn this.cache.roles[arguments.role].webskins[arguments.webskin] />
		<cfelseif isvalid("uuid",arguments.permission)>
			<cfreturn this.cache.roles[arguments.role].permissions[arguments.permission] />
		<cfelse>
			<cfthrow message="getCache requires the permission or webskin argument" />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteCache" access="public" output="false" returntype="void" hint="Deletes the specified cache. Doesn't error check.">
		<cfargument name="role" type="uuid" required="true" hint="The role to find" />
		<cfargument name="permission" type="string" required="false" default="" hint="The permission to find" />
		<cfargument name="object" type="string" required="false" default="" hint="The object to find" />
		<cfargument name="webskin" type="string" required="false" default="" hint="The webskin to cache" />
		
		<cfif not structkeyexists(this.cache.roles,arguments.role)>
			<cfset this.cache.roles[arguments.role] = structnew() />
			<cfset this.cache.roles[arguments.role].barnacles = structnew() />
			<cfset this.cache.roles[arguments.role].permissions = structnew() />
			<cfset this.cache.roles[arguments.role].webskins = structnew() />
		</cfif>
		
		<cfif isvalid("uuid",arguments.object) and isvalid("uuid",arguments.permission)>
			<!--- Remove barnacle --->
			<cfset structdelete(this.cache.roles[arguments.role].barnacles[arguments.object],arguments.permission) />
		<cfelseif isvalid("uuid",arguments.object)>
			<!--- Remove object --->
			<cfset structdelete(this.cache.roles[arguments.role].barnacles,arguments.object) />
		<cfelseif isvalid("uuid",arguments.permission)>
			<!--- Remove permission --->
			<cfif structkeyexistse(this.cache.roles[arguments.role].permissions,arguments.permission)>
				<!--- Remove permission from general permissions --->
				<cfset structdelete(this.cache.roles[arguments.role].permissions,arguments.permission) />
			<cfelse>
				<!--- Remove permission from all objects --->
				<cfloop collection="#this.cache.roles[arguments.role].barnacles#" item="arguments.object">
					<cfif structkeyexists(this.cache.roles[arguments.role].barnacles[arguments.object],arguments.permission)>
						<cfset structdelete(this.cache.roles[arguments.role].barnacles[arguments.object],arguments.permission) />
					</cfif>
				</cfloop>
			</cfif>
		<cfelseif len(arguments.webskin)>
			<!--- Remove webskin --->
			<cfset structdelete(this.cache.roles[arguments.role].webskins,arguments.webskin) />
		<cfelse>
			<!--- If only the role was provided, clear the entire role --->
			<cfset structclear(this.cache.roles[arguments.role].barnacles) />
			<cfset structclear(this.cache.roles[arguments.role].permissions) />
			<cfset structclear(this.cache.roles[arguments.role].webskins) />
		</cfif>
	</cffunction>
	
	
	<cffunction name="getLookup" access="public" output="false" returntype="string" hint="Returns the objectid for a specified label">
		<cfargument name="role" type="string" required="false" default="" hint="The title of the role to lookup" />
		<cfargument name="permission" type="string" required="false" default="" hint="The title of the permission to lookup" />
		
		<cfif len(arguments.role) and structkeyexists(this.cache.rolelookup,arguments.role)>
			<cfreturn this.cache.rolelookup[arguments.role] />
		<cfelseif len(arguments.permission) and structkeyexists(this.cache.permissionlookup,arguments.permission)>
			<cfreturn this.cache.permissionlookup[arguments.permission] />
		</cfif>
		
		<cfreturn "" />
	</cffunction>
	
	<cffunction name="hasLookup" access="public" output="false" returntype="boolean" hint="Returns true if the lookup is cached">
		<cfargument name="role" type="string" required="false" default="" hint="The title of the role to lookup" />
		<cfargument name="permission" type="string" required="false" default="" hint="The title of the permission to lookup" />
		
		<cfif len(arguments.role)>
			<cfreturn structkeyexists(this.cache.rolelookup,arguments.role) />
		<cfelseif len(arguments.permission)>
			<cfreturn structkeyexists(this.cache.permissionlookup,arguments.permission) />
		</cfif>
		
		<cfreturn false />
	</cffunction>
	
	<cffunction name="setLookup" access="public" output="false" returntype="uuid" hint="Stores an objectid for a specified label">
		<cfargument name="role" type="string" required="false" default="" hint="The title of the role to lookup" />
		<cfargument name="permission" type="string" required="false" default="" hint="The title of the permission to lookup" />
		<cfargument name="objectid" type="uuid" required="true" hint="The objectid of the item to store" />
		
		<cfif len(arguments.role)>
			<cfset this.cache.rolelookup[arguments.role] = arguments.objectid />
		<cfelse>
			<cfset this.cache.permissionlookup[arguments.permission] = arguments.objectid />
		</cfif>
		
		<cfreturn arguments.objectid />
	</cffunction>
	
	<cffunction name="removeLookup" access="public" output="false" returntype="void" hint="Removes the specified objectid or label">
		<cfargument name="role" type="string" required="false" default="" hint="The title of the role to lookup" />
		<cfargument name="permission" type="string" required="false" default="" hint="The title of the permission to lookup" />
		
		<cfset var i = 0 />
		
		<cfif len(arguments.role)>
			<cfif isvalid("uuid",arguments.role)>
				<cfloop collection="#this.cache.rolelookup#" item="i">
					<cfif this.cache.rolelookup[i] eq arguments.role>
						<cfset structdelete(this.cache.rolelookup,i) />
						<cfbreak />
					</cfif>
				</cfloop>
			<cfelse>
				<cfset this.cache.rolelookup[arguments.role] = arguments.objectid />
			</cfif>
		<cfelse>
			<cfif isvalid("uuid",arguments.permission)>
				<cfloop collection="#this.cache.permissionlookup#" item="i">
					<cfif this.cache.permissionlookup[i] eq arguments.permission>
						<cfset structdelete(this.cache.permissionlookup,i) />
						<cfbreak />
					</cfif>
				</cfloop>
			<cfelse>
				<cfset this.cache.permissionlookup[arguments.permission] = arguments.objectid />
			</cfif>
		</cfif>
	</cffunction>
	
	
	<!--- THESE FUNCTIONS ARE DEPRECIATED --->
	<cffunction name="getUsers" access="public" output="false" returntype="string" hint="Returns a list of the users that have this permission">
		<cfargument name="permission" type="uuid" required="true" hint="The permission to query" />
	
		<cfset var qRoles = "" />
		<cfset var qGroups = "" />
		<cfset var group = "" />
		<cfset var result = "" />
	
		<farcry:deprecated message="security.getUsers() is deprecated" />
		
		<!--- Get roles with that permission --->
		<cfquery datasource="#application.dsn#" name="qRoles">
			select	parentid
			from	#application.dbowner#farRole_aPermissions
			where	data=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.permission#" />
		</cfquery>
		
		<cfif qRoles.recorcount>
			<!--- Get the groups for those roles --->
			<cfquery datasource="#application.dsn#" name="qGroups">
				select	data
				from	#appliation.dbowner#farRole_aGroups
				where	parentid in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valuelist(qRoles.parentid)#" />)
			</cfquery>
			
			<!--- Get the users for those groups --->
			<cfloop query="qGroups">
				<cfif structkeyexist(this.userdirectories,listlast(data,"_"))>
					<cfloop list="#this.userdirectories['CLIENTUD'].getGroupUsers(listfirst(data,'_'))#" index="group">
						<cfset result = application.factory.oUtils.listMerge(result,"#group#_#listlast(data,'_')#") />
					</cfloop>
				</cfif>
			</cfloop>
		</cfif>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="initRequestMode" access="public" output="false" returntype="struct" hint="Sets up the request.mode struct and other request settings based on the current users security permissions">
		<cfargument name="stURL" type="struct" required="true" default="#url#" hint="Reference to the URL struct" />

		<cfscript>
		request.fc.bShowTray = true;
			
		// init request.mode with defaults
		request.mode = structNew();
		request.mode.design = 0;
		request.mode.flushcache = 0;
		request.mode.rebuild = "auto";
		request.mode.showdraft = 0;
		request.mode.ajax = 0;
		request.mode.tracewebskins = 0;
		request.mode.profile = 0;
		
		// Developer Mode
		request.mode.bDeveloper = 0;
		
		// container management
		// default to off, conjurer determines permissions based on nav-node
		request.mode.showcontainers = 0; 
		
		// miscellaneous options to be added
		request.mode.showtables = 0;
		request.mode.showerror = 0;
		request.mode.showdebugoutput = 0;
		
		// admin options visible in page
		if (IsDefined("session.dmSec.Authentication.bAdmin")) {
			request.mode.bAdmin = session.dmSec.Authentication.bAdmin; 
		} else {
			request.mode.bAdmin = 0; // default to off
		}
			
		// if user has admin priveleges, determine mode values
		if (request.mode.bAdmin) {
		// designmode
			if (isDefined("arguments.stURL.designmode")) {
				request.mode.design = val(arguments.stURL.designmode);
				session.dmSec.Authentication.designmode = request.mode.design;
			} else if (isDefined("session.dmSec.Authentication.designmode")) {
				request.mode.design = session.dmSec.Authentication.designmode;
			} else {
				request.mode.design = 0;
			}
		// profile mode
			if (isDefined("arguments.stURL.profile")) {
				request.mode.profile = val(arguments.stURL.profile);
			} else {
				request.mode.profile = 0;
			}
		// webskintrace
			if (isDefined("arguments.stURL.tracewebskins")) {
				request.mode.tracewebskins = arguments.stURL.tracewebskins;
			} else {
				request.mode.tracewebskins = 0;
			}
		
		// bypass caching
			if (isDefined("arguments.stURL.flushcache")) {
				request.mode.flushcache = val(arguments.stURL.flushcache);
				session.dmSec.Authentication.flushcache = request.mode.flushcache;
			} else if (isDefined("session.dmSec.Authentication.flushcache")) {
				request.mode.flushcache = session.dmSec.Authentication.flushcache;
			} else {
				request.mode.flushcache = 0;
			}
		
		// view content as stage
			if (isDefined("arguments.stURL.showdraft")) {
				request.mode.showdraft = val(arguments.stURL.showdraft);
				session.dmSec.Authentication.showdraft = request.mode.showdraft;
			} else if (isDefined("session.dmSec.Authentication.showdraft")) {
				request.mode.showdraft = session.dmSec.Authentication.showdraft;
			} else {
				request.mode.showdraft = 0;
			}
		
		// disable tray
			if (isDefined("arguments.stURL.bShowTray")) {
				request.fc.bShowTray = val(arguments.stURL.bShowTray);
				//session.dmProfile.bShowTray = request.fc.bShowTray;
			} else if (isDefined("session.dmProfile.bShowTray")) {
				//request.fc.bShowTray = session.dmProfile.bShowTray;
			} else {
				//request.fc.bShowTray = 0;
				//session.dmProfile.bShowTray = request.fc.bShowTray;
			}
		
		// rebuild page / everything
			if (isDefined("arguments.stURL.rebuild")) {
				request.mode.rebuild = arguments.stURL.rebuild;
				if (url.rebuild eq "page"){
					request.mode.flushcache = 1;
		}
				else if (arguments.stURL.rebuild eq "all"){
					application.fc.lib.objectbroker.init(bFlush=true);
				}
			}
			else {
				request.mode.rebuild = "auto";
			}
		
		}
		
		// set valid status for content
		if (request.mode.showdraft) {
			request.mode.lValidStatus = "draft,pending,approved";
		} else {
			request.mode.lValidStatus = "approved";
		}
	
		// ajaxmode
		// Ensure that if ajaxmode is defined multiple times, then we only get the last one.
		if (structKeyExists(arguments.stURL, "ajaxmode")) {
			arguments.stURL.ajaxmode = listLast(arguments.stURL.ajaxmode);
		}
		if (isDefined("form") and structKeyExists(form, "ajaxmode")) {
			form.ajaxmode = listLast(form.ajaxmode);
		}
		
		if ((isDefined("arguments.stURL.ajaxmode") and arguments.stURL.ajaxmode) or (isDefined("form.ajaxmode") and form.ajaxmode)) {
			request.mode.ajax = true;
		} else {
			request.mode.ajax = false;
		}
			
		// Deprecated variables
		// TODO remove these when possible
		request.lValidStatus = request.mode.lValidStatus; //deprecated
		</cfscript>
		
		<cfreturn application.fapi.success() />
	</cffunction>
</cfcomponent>