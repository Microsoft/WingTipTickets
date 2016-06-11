﻿<#
.Synopsis
	WingtipTickets (WTT) Demo Environment.
.DESCRIPTION
	This script is used to edit the Application Settings values of the web.config file in the Azure WebSites WebDeploy Zip Package.
.EXAMPLE
	Set-WTTEnvironmentWebConfig -WTTEnvironmentApplicationName <string> -AzureWebSiteWebDeployPackageName <string> -SearchServicePrimaryManagementKey <string>
#>
function Set-WTTEnvironmentWebConfig
{
	[CmdletBinding()]
	Param
	(
		# WTT Environment Application Name
		[Parameter(Mandatory=$true)]
		[String]
		$WTTEnvironmentApplicationName,
		
        # Azure Resource Group Name
        [Parameter(Mandatory=$true)]
		[String]
        $azureResourceGroupName,

		# WTT Environment Application Name
		[Parameter(Mandatory=$true)]
		[String]
		$Websitename,

		# Primary Azure SQL Database Server Name
		[Parameter(Mandatory=$false)]
		[String]
		$AzureSqlServerPrimaryName,

		# Secondary Azure SQL Database Server Name
		[Parameter(Mandatory=$false)]
		[String]
		$AzureSqlServerSecondaryName,

		# Azure SQL Database Server Administrator User Name
		[Parameter(Mandatory=$false)]
		[String]
		$AdminUserName,

		# Azure SQL Database Server Adminstrator Password
		[Parameter(Mandatory=$false)]
		[String]
		$AdminPassword,

		# Azure SQL Database Name
		[Parameter(Mandatory=$false)]
		[String]
		$AzureSqlDatabaseName,
	
		# Azure Search Service Name
		[Parameter(Mandatory = $true)] 
		[String]$SearchName,

		# Azure Search Service Primary Management Key
		[Parameter(Mandatory = $true)] 
		[String]$SearchServicePrimaryManagementKey,

		# Azure DocumentDb Name
		[Parameter(Mandatory = $false)]
		[String]$azureDocumentDbName,

		# Azure DocumentDb Key
		[Parameter(Mandatory = $false)] 
		[String]$documentDbPrimaryKey,
        
        # Azure Power BI Signing Key
        [Parameter(Mandatory = $false)] 
        $powerbiSigningKey,

        # Azure Power BI Workspace Collection Name
        [Parameter(Mandatory = $false)] 
        $powerbiWorkspaceCollection,

        # Azure Power BI Workspace ID
        [Parameter(Mandatory = $false)] 
        $powerbiWorkspaceId,

        # Azure Power BI Seat Map ID
        [Parameter(Mandatory = $false)] 
        $seatMapReportID
	)

	Process
	{
		try
		{
			WriteLabel("Setting Config Settings")

			# Check Defaults
			if($AdminUserName -eq "")
			{
				$AdminUserName = "developer"
			}

			if($AdminPassword -eq "")
			{
				$AdminPassword = "P@ssword1"
			}

			if($AzureSqlDatabaseName -eq "")
			{
				$AzureSqlDatabaseName = "Customer1"
			}

			$docDBName = "https://$azureDocumentDbName.documents.azure.com:443/"

			# Build web application settings
			$settings = New-Object Hashtable
			$settings = 
			@{
					# Tenant Settings
					"TenantName" = "$WTTEnvironmentApplicationName"; 
					"TenantEventType" = "pop"; # This is not set from main script, used the default
					"TenantPrimaryDatabaseServer" = "$AzureSqlServerPrimaryName"; 
					"TenantSecondaryDatabaseServer" = "$AzureSqlServerSecondaryName";
					"TenantDatabase" = "$AzureSqlDatabaseName"; 

					# Recommendation Setings
					"RecommendationDatabaseServer" = "$AzureSqlServerPrimaryName";
					"RecommendationDatabase" = "Recommendations";

					# Shared Settings
					"DatabaseUser" = "$AdminUserName"; 
					"DatabasePassword" = "$AdminPassword"; 
					"AuditingEnabled" = "false" # This is not set from main script, used the default
					"RunningInDev" = "false";

					# Keys
					"SearchServiceKey" = "$SearchServicePrimaryManagementKey"; 
					"SearchServiceName" = "$SearchName"; 
					"DocumentDbUri" = "$docDBName"; 
					"DocumentDbKey" = "$documentDbPrimaryKey";

                    # Power BI Settings
                    "powerbiSigningKey" = "$powerbiSigningKey";
                    "powerbiWorkspaceCollection" = "$powerbiWorkspaceCollection";
                    "powerbiWorkspaceId" = "$powerbiWorkspaceId";
                    "SeatMapReportId" = "$seatMapReportID"
			}

			# Add the settings to the website
			$null = Set-AzureRMWebApp -AppSettings $settings -Name $websiteName -ResourceGroupName $azureResourceGroupName

			$null = Restart-AzureRMWebApp -Name $websiteName -ResourceGroupName $azureResourceGroupName
			
			WriteValue("Successful")
		}
		catch
		{
			WriteError($Error)
		}
	}
}

