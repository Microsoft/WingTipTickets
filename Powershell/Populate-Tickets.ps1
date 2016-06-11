﻿<#
.Synopsis
	WingtipTickets (WTT) Demo Environment.
.DESCRIPTION
	This script is used to create a new WingtipTickets (WTT) Demo Environment.
.EXAMPLE
	Populate-Tickets 
WingTipTickets PowerShell Version 2.6
#>

function Populate-Tickets
{
	[CmdletBinding()]
	Param
	(
		# Resource Group Name
		[Parameter(Mandatory=$true)]
		[String]
		$azureResourceGroupName,

        # Azure SQL Database Server Administrator User Name
		[Parameter(Mandatory=$true)]
		[String]
		$AdminUserName,

		# Azure SQL Database Server Adminstrator Password
		[Parameter(Mandatory=$true)]
		[String]
		$AdminPassword,
        
        # Azure Tenant SQL Database Name
		[Parameter(Mandatory=$false)]
		[String]		
        $AzureSqlDatabaseName,

		# Azure SQL server name for connection.
		[Parameter(Mandatory=$true)]
		[String]
		$AzureSqlServerName
    )

    $date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    $customerID = 1

    #Test SQL Server Connection
	$testSQLConnection = Test-WTTAzureSQLConnection -AzureSqlServerName $AzureSqlServerName -adminUserName $AdminUserName -adminPassword $AdminPassword -AzureSqlDatabaseName $AzureSqlDatabaseName -azureResourceGroupName $azureResourceGroupName
	if ($testSQLConnection -notlike "success")
	{
		WriteError("Unable to connect to SQL Server")
	}
	Else
	{
        $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query "set Identity_insert dbo.tickets on" -QueryTimeout 0 -SuppressProviderContextWarning
        $concertID = @(1..2)

        foreach ($concert in $concertID)
        {
            $seatArray = @(Section101)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 1
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(Section102)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 2
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(Section103)
            foreach($seat in $seatArray)
            {     
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 3
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(section201to04)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 4
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(section201to04)
            foreach($seat in $seatArray)
            { 
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 5
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(section201to04)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 6
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(section201to04)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 7
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(Section205to07)
            foreach($seat in $seatArray)
            { 
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 8
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(Section205to07)
            foreach($seat in $seatArray)
            {  
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 9
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }

            $seatArray = @(Section208)
            foreach($seat in $seatArray)
            {
                $name = "Ticket for user admin to concert-$concert"
                $ticketLevelID = 10
                $command = "Insert [dbo].[Tickets]([CustomerID], [Name], [TicketLevelID], [ConcertID], [PurchaseDate], [SeatNumber]) Values ($customerID, '$name', $ticketLevelID, $concert, '$date', $seat)"
                $updateDB = Invoke-Sqlcmd -Username "$AdminUserName@$AzureSqlServerName" -Password "$AdminPassword" -ServerInstance "$AzureSqlServerName.database.windows.net" -Database $AzureSqlDatabaseName -Query $command -QueryTimeout 0 -SuppressProviderContextWarning
            }
        }
    }
}

function section101
{
    Get-Random -count 15 -InputObject (1..60)
}
function section201to04
{
    Get-Random -Count 4 -InputObject (1..8)
}
function Section102
{
    Get-Random -Count 25 -InputObject (1..100)
}
function Section103
{
    Get-Random -Count 65 -InputObject (1..175)
}
function Section205to07
{
    Get-Random -Count 9 -InputObject (1..32)
}
function Section208
{
    Get-Random -Count 45 -InputObject (1..175)
}