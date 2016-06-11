﻿<#
.Synopsis
	WingtipTickets (WTT) Demo Environment.
.DESCRIPTION
	This script is used to create a new WingtipTickets (WTT) Demo Environment.
.EXAMPLE

WingTipTickets PowerShell Version 2.6 - Power BI
#>
function New-WTTPowerBI
{
	[CmdletBinding()]
	Param
	(
		# Resource Group Name
		[Parameter(Mandatory=$true)]
		[String]
		$azureResourceGroupName,

		# WTT Environment Application Name
		[Parameter(Mandatory=$true)]
		[String]
		$AzurePowerBIName,

		# Azure SQL Database Server Primary Name
		[Parameter(Mandatory=$false)]
		[String]
		$AzureSqlServerName,

		# Azure SQL Database Server Administrator User Name
		[Parameter(Mandatory=$true)]
		[String]
		$adminUserName,

		# Azure SQL Database Server Adminstrator Password
		[Parameter(Mandatory=$true)]
		[String]
		$adminPassword,

		# Azure Tenant SQL Database Name
		[Parameter(Mandatory=$true)]
		[String]
		$azureSqlDatabaseName,

		# Azure DataWarehouse SQL Database Name
		[Parameter(Mandatory=$true)]
		[String]
		$azureDWDatabaseName,

		# Azure Power BI Location
		[Parameter(Mandatory=$true)]
		[String]
        $azurePowerBILocation
	)

    # Set environment variables
    $azurePowerBIWorkspaceCollection = $AzurePowerBIName
    $powerBIReportFiles = ".\Resources\PowerBI"
    $log = Get-ChildItem .\powerbi.txt -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    Try
    {
        #Check status of Power BI service
        $status = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.PowerBI
        if ($status.RegistrationState -ne "Registered")
        {
            $null = Register-AzureRmResourceProvider -ProviderNamespace Microsoft.PowerBI -Force
        }

        WriteLabel("Checking for Azure Power BI Service $AzurePowerBIName")
        
        $powerBIService = Find-AzureRmResource -ResourceGroupNameContains $azureResourceGroupName -ResourceType "Microsoft.PowerBI/workspaceCollections" -ResourceNameContains $AzurePowerBIName -ExpandProperties -ErrorAction SilentlyContinue
        if($powerBIService.Name -eq $AzurePowerBIName)
        {
            WriteValue("Failed")
            WriteError("$AzurePowerBIName Power BI service already exists.")
            Remove-AzureRmResource -ResourceName $AzurePowerBIName -ResourceType "Microsoft.PowerBI/workspaceCollections" -ResourceGroupName $azureResourceGroupName -ErrorAction SilentlyContinue -force
            Start-Sleep -Seconds 300
        }
        else
        {
            WriteValue("Success")
        }

        # Load ADAL Assemblies
        $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
        $null = [System.Reflection.Assembly]::LoadFrom($adal)
        $null = [System.Reflection.Assembly]::LoadFrom($adalforms)
        # Load Power BI assemblies
        $nugetImport = .\NuGet.\NuGet.exe restore ".\NuGet\packages.config" -PackagesDirectory ".\Nuget\Packages"
        $powerBIDLL = Get-ChildItem -Recurse ".\Nuget\packages\*PowerBI.Core*" -Include *.dll
        $jwtDLL = Get-ChildItem -Recurse ".\Nuget\packages\*System.IdentityModel.Tokens.Jwt*" -Include *.dll
        add-type -path $powerBIDLL
        add-type -path $jwtDLL
        $powerBIAssemblies = New-Object Microsoft.PowerBI.Security.PowerBIToken

        # Setup authentication to Azure
        #Get Azure Tenant ID
        $tenantId = (Get-AzureRmContext).Tenant.TenantId
        $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
        # Set redirect URI for Azure PowerShell
        $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
        # Set Resource URI to Azure Service Management API
        $resourceAppIdURI = "https://management.core.windows.net/"
        # Set Authority to Azure AD Tenant
        $authority = "https://login.windows.net/$tenantId"
        # Create Authentication Context tied to Azure AD Tenant
        $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
        $azureSubscriptionID = (Get-AzureRmContext).Subscription.SubscriptionId

        Try
        {
            # Acquire token
            $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
            $authHeader = $authResult.CreateAuthorizationHeader()
            $headers = @{"Authorization" = $authHeader}     
            
            WriteLabel("Deploying Power BI Workspace Collection")
            #create Power BI Workspace Collection
            $powerBIWorkspaceCollectionURL =  "https://management.azure.com/subscriptions/$azureSubscriptionID/resourceGroups/$azureResourceGroupName/providers/Microsoft.PowerBI/workspaceCollections/$azurePowerBIWorkspaceCollection"+"?api-version=2016-01-29"
            $powerBIWorkspaceCollection = "{
                                                        ""location"": ""$azurePowerBILocation"",
                                                        ""tags"": {},
                                                        ""sku"": {
                                                            ""name"": ""S1"",
                                                            ""tier"": ""Standard""
                                                        }
                                            }"
            $powerBIWorkspaceCollectionCreate =  Invoke-RestMethod -Uri $powerBIWorkspaceCollectionURL -Method Put -Body $powerBIWorkspaceCollection -ContentType "application/json; charset=utf-8" -Headers $headers
            If($powerBIWorkspaceCollectionCreate.properties.provisioningState -eq "Succeeded")
            {
                WriteValue("Successful")
            }
            Else
            {
                WriteError("Unable to find Power BI Workspace Collection")
            }

            #$powerBIWorkspaceCollectionCreate.name | Out-File powerbi.txt -Append
            
            #Get Power BI Workspace Collection Key
            $powerBIWorkspaceCOllectionKeyURL =  "https://management.azure.com/subscriptions/$azureSubscriptionID/resourceGroups/$azureResourceGroupName/providers/Microsoft.PowerBI/workspaceCollections/$azurePowerBIWorkspaceCollection/listKeys?api-version=2016-01-29"
            $powerBIWorkspaceCOllectionKey = Invoke-RestMethod -Uri $powerBIWorkspaceCOllectionKeyURL -Method POST -Headers $headers
            $pbikey = $powerBIWorkspaceCOllectionKey.key1 
            $pbikey | Out-File .\powerbi.txt -Append
        }
        Catch
        {
            Write-Error "Error: $Error"
        }
        Try
        {
            #Create Power BI Provisioning Token
            $appToken = [Microsoft.PowerBI.Security.PowerBIToken]::CreateProvisionToken($azurePowerBIWorkspaceCollection)
            $token = $appToken.Generate($pbikey)
            
            $workspaceExist = $false
            WriteLabel("Deploying Power BI Workspace")
            Do
            {
                #Create Power BI Workspace
                $powerBIWorkspaceURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces"
                $header = @{authorization = "AppToken $token"}
                $powerBIWorkspaceCreate =  Invoke-RestMethod -Uri $powerBIWorkspaceURL -Method POST -ContentType "application/json" -Headers $header
                $powerBIWorkspaceGet =  Invoke-RestMethod -Uri $powerBIWorkspaceURL -Method GET -ContentType "application/json" -Headers $header

                If(!$powerBIWorkspaceGet.WorkspaceId)
                {
                    WriteValue("Successful")
                    $workspaceExist = $true
                }
                Else
                {
                    WriteError("Unable to find Power BI Workspace")
                    $workspaceExist = $false
                }

            }until($workspaceExist -eq $true)

            # Get the Power BI workspace ID
            $powerBIWorkspaceGet = Invoke-RestMethod -Uri $powerBIWorkspaceURL -Method GET -ContentType "application/json" -Headers $header
            $powerBIWorkspaceID = $powerBIWorkspaceGet.Value.WorkspaceId
            $powerBIWorkspaceID | Out-File .\powerbi.txt -Append
        
            #Import Power BI Reports
            $reports = Get-ChildItem "$powerBIReportFiles\*.pbix"
            ForEach($report in $reports)
            {   
                $powerBIWorkspace =
                Switch($report.Name)
                {
                    'WTTReports1.pbix' {'TicketSalesDashboard'}                  
                    'WTTReports2.pbix' {'TicketSalesQuantity'}
                    'seatingMap.pbix' {'Seatingmap'}
                }

                #Create Power BI Dev Token
                $appToken = [Microsoft.PowerBI.Security.PowerBIToken]::CreateDevToken($azurePowerBIWorkspaceCollection, $powerBIWorkspaceID)
                $token = $appToken.Generate($pbikey)
                $header = @{authorization = "AppToken $token"}

                WriteLabel("Uploading Power BI Report $report")
                
                # Configure settings to upload Power BI Report
                $fileBin = [IO.File]::ReadAllBytes($report)                                                                                                  
                $enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")                                               
                $fileEnc = $enc.GetString($fileBin)                                                                 
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"
                $bodyLines = (
                    "--$boundary",
                    "Content-Disposition: form-data $LF",
                    $fileEnc,
	                "--$boundary--$LF"
                    ) -join $LF
                
                # Upload Power BI Report
                $powerBIUploadReportsURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/imports?datasetDisplayName=$powerBIWorkspace"
                $powerBIUploadReportsCreate = Invoke-RestMethod -Uri $powerBIUploadReportsURL -Method POST -ContentType "multipart/form-data; boundary=`"$boundary`"" -Headers $header -Body $bodyLines
                Start-Sleep -Seconds 30
                $powerBIReportsURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/reports"
                $powerBIReportsGet = Invoke-RestMethod -Uri $powerBIReportsURL -Method GET -ContentType "application/json" -Headers $header
                  
                If($powerBIReportsGet.value.name -match $powerBIWorkspace)
                {
                    WriteValue("Successful")
                }
                Else
                {
                    WriteError("Unable to find Power BI Report")                        
                }
                
                # Get Power BI report Import ID
                $powerBIImportsURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/imports"
                $powerBIImports = Invoke-RestMethod -Uri $powerBIImportsURL -Method GET -ContentType "application/json" -Headers $header
                if ($powerBIImports.value | Where-Object {$_.name -eq $powerBIWorkspace})
                {
                    $bi = $powerBIImports.value | Where-Object {$_.name -eq $powerBIWorkspace}
                    $powerBIDataSetID = $bi.datasets.id
                }
                                
                if($powerBIWorkspace -ne 'Seatingmap')
                {       
                    WriteLabel("Setting Power BI Report $report Connection String")
                    #Get Data Sources Gateway
                    $powerBIGatewayDataSourcesGetURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.GetBoundGatewayDatasources"
                    $powerBIGatewayDataSourcesGet = Invoke-RestMethod -Uri $powerBIGatewayDataSourcesGetURL -Method GET -ContentType "application/json" -Headers $header
   
                    #Post All connections
                    $powerBISetAllConnectionsURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.SetAllConnections"
                    $powerBISetAllConnectionsConnString = "{
                                                            ""connectionString"": ""Data source=tcp:$AzureSqlServerName.database.windows.net,1433;initial catalog=$AzureSqlDWDatabaseName;Persist Security info=True;Encrypt=True;TrustServerCertificate=False""
                                                            }"
                    $powerBISetAllConnectionsPost = Invoke-RestMethod -Uri $powerBISetAllConnectionsURL -Method POST -ContentType "application/json" -Body $powerBISetAllConnectionsConnString -Headers $header
                
                    #Check for Data source update
                    $powerBIGatewayDataSourcesGetURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.GetBoundGatewayDatasources"
                    $powerBIGatewayDataSourcesGet = Invoke-RestMethod -Uri $powerBIGatewayDataSourcesGetURL -Method GET -ContentType "application/json" -Headers $header
                    $powerBIDataSourcesGatewayID = $powerBIGatewayDataSourcesGet.value.gatewayid
                    $powerBIGatewayDataID = $powerBIGatewayDataSourcesGet.value.id
                    
                    $powerBIDataSourcesPatchURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/gateways/$powerBIDataSourcesGatewayID/datasources/$powerBIGatewayDataID"
                    $powerBIDataSourcesPatchBody = "{
                                                ""credentialType"": ""Basic"",
                                                ""basicCredentials"": {
                                                    ""username"": ""$adminUserName"",
                                                    ""password"": ""$adminPassword""
                                                }
                                            }"

                    $powerBIDataSourcesPatch = Invoke-RestMethod -Uri $powerBIDataSourcesPatchURL -Method PATCH -ContentType "application/json" -Body $powerBIDataSourcesPatchBody -Headers $header
                    $powerBIGetReportURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/reports"
                    $powerBIGetReport = Invoke-RestMethod -Uri $powerBIGetReportURL -Method GET -ContentType "application/json" -Headers $header
                    $report = $powerBIGetReport.value | Where-Object {$_.name -eq $powerBIWorkspace}
                    if($report) 
                    {
                        WriteValue("Successful")
                    }
                    else
                    {
                        WriteError("Failed")
                    }

                    # Get Dashboard Report ID
                    $powerBIGetReportURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/reports"
                    $powerBIGetReport = Invoke-RestMethod -Uri $powerBIGetReportURL -Method GET -ContentType "application/json" -Headers $header
                    $report = $powerBIGetReport.value | Where-Object {$_.name -eq "ticketsalesdashboard"}
                    $reportid = $report.id
                    $updateDB = Invoke-Sqlcmd -Username "developer@$AzureSqlServerName" -Password "P@ssword1" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query "UPDATE ApplicationDefault SET VALUE='$reportid' WHERE Code='DefaultReportID'" -QueryTimeout 0 -SuppressProviderContextWarning -ErrorAction SilentlyContinue                   
                }

                # Set Seating Chart Database Connection
                else
                {
                    WriteLabel("Setting Power BI Report $report Connection String")
                    #Get Data Sources Gateway
                    $powerBIGatewayDataSourcesGetURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.GetBoundGatewayDatasources"
                    $powerBIGatewayDataSourcesGet = Invoke-RestMethod -Uri $powerBIGatewayDataSourcesGetURL -Method GET -ContentType "application/json" -Headers $header
                    
                    #Post All connections
                    $powerBISetAllConnectionsURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.SetAllConnections"
                    $powerBISetAllConnectionsConnString = "{
                                                            ""connectionString"": ""Data source=tcp:$AzureSqlServerName.database.windows.net,1433;initial catalog=$AzureSqlDatabaseName;Persist Security info=True;Encrypt=True;TrustServerCertificate=False""
                                                            }"
                    $powerBISetAllConnectionsPost = Invoke-RestMethod -Uri $powerBISetAllConnectionsURL -Method POST -ContentType "application/json" -Body $powerBISetAllConnectionsConnString -Headers $header
                
                    #Check for Data source update
                    $powerBIGatewayDataSourcesGetURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/datasets/$powerBIDataSetID/Default.GetBoundGatewayDatasources"
                    $powerBIGatewayDataSourcesGet = Invoke-RestMethod -Uri $powerBIGatewayDataSourcesGetURL -Method GET -ContentType "application/json" -Headers $header
                    $powerBIDataSourcesGatewayID = $powerBIGatewayDataSourcesGet.value.gatewayid
                    $powerBIGatewayDataID = $powerBIGatewayDataSourcesGet.value.id

                    $powerBIDataSourcesPatchURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/gateways/$powerBIDataSourcesGatewayID/datasources/$powerBIGatewayDataID"
                    $powerBIDataSourcesPatchBody = "{
                                                ""credentialType"": ""Basic"",
                                                ""basicCredentials"": {
                                                    ""username"": ""$adminUserName"",
                                                    ""password"": ""$adminPassword""
                                                }
                                            }"

                    $powerBIDataSourcesPatch = Invoke-RestMethod -Uri $powerBIDataSourcesPatchURL -Method PATCH -ContentType "application/json" -Body $powerBIDataSourcesPatchBody -Headers $header

                    # Get Seating Chart Report ID
                    $powerBIGetReportURL = "https://api.powerbi.com/beta/collections/$azurePowerBIWorkspaceCollection/workspaces/$powerBIWorkspaceID/reports"
                    $powerBIGetReport = Invoke-RestMethod -Uri $powerBIGetReportURL -Method GET -ContentType "application/json" -Headers $header
                    $report = $powerBIGetReport.value | Where-Object {$_.name -eq "seatingmap"}
                    $reportid = $report.id
                    $reportid | Out-File .\powerbi.txt -Append

                    if($report)
                    {
                        WriteValue("Successful")
                    }
                    else
                    {
                        WriteError("Failed")
                    }
                }              
            }
        }
        Catch
        {
            Write-Error "Error: $Error"
        }
    }  
    Catch
    {
        Write-Error "Error: $Error"
    }
}