using namespace Microsoft.PowerShell.SHiPS

[SHiPSProvider()]
class CMRoot : SHiPSDirectory
{
    # static member to keep track of CIM sessions
    static [System.Collections.Generic.List``1[Microsoft.Management.Infrastructure.CimSession]] $sessions
    
    # Default constructor
    CMRoot([string]$name):base($name)
    {
    }

    [object[]] GetChildItem()
    {
        $obj = @()

        # If sessions are present, create machine object for those sessions
        if([CMRoot]::sessions){
            [CMRoot]::sessions | ForEach-Object {
                $obj += [CMMachine]::new($_.ComputerName, $_)
            }
        }
        # Else create a default session for localhost
        else{
            $obj += [CMMachine]::new('localhost')
        }
        return $obj
    }
}

[SHiPSProvider()]
class CMMachine : SHiPSDirectory
{
    [Microsoft.Management.Infrastructure.CimSession]$Cimsession = $null

    # Given a machine name, create a cimsession and add to static member
    CMMachine([string]$name):base($name)
    {
        $this.CimSession = New-CimSession -ComputerName $name
        [CMRoot]::Sessions += $this.CimSession
    }

    # Given a cimsession, add to static member
    CMMachine([string]$name, [Microsoft.Management.Infrastructure.CimSession]$cimsession):base($name)
    {
        $this.CimSession = $cimsession
    }

    [object[]] GetChildItem()
    {
        $obj = @()
        
        # Find all the namespace under root namespace
        $namespaces = (Get-CimInstance -Namespace root -ClassName __namespace -CimSession $this.CimSession).Name | Sort-Object
        foreach ($namespace in $namespaces) {
            $obj += [CMNamespace]::new('root',$namespace,$this.CimSession)
        }
        return $obj
    }
}

[SHiPSProvider()]
class CMNamespace : SHiPSDirectory
{
    [Microsoft.Management.Infrastructure.CimSession]$CimSession = $null
    [string]$Namespace = 'root'
    [string]$Type = 'Namespace'

    CMNamespace([string]$parent, [string]$name, [Microsoft.Management.Infrastructure.CimSession]$cimsession):base($name)
    {
        $this.Namespace = Join-Path $parent $name
        $this.CimSession = $cimsession
    }
     
    [object[]] GetChildItem()
    {
        $obj = @()

        # Find all the child namespaces
        $namespaces = (Get-CimInstance -Namespace $this.Namespace -ClassName __namespace -CimSession $this.CimSession).Name | Sort-Object
        $namespacesToSkip = @('ms_409')
        foreach ($namespace in $namespaces) {
            if($namespacesToSkip -notcontains $namespace){
                $obj += [CMNamespace]::new($this.Namespace, $namespace, $this.CimSession)
            }
        }
        
        # Find all the classes in the given namespace
        $classNamesToSkip = @('ms_409'
                              'CIM_Indication'
                              'CIM_ClassIndication'
                              'CIM_ClassDeletion'
                              'CIM_ClassCreation'
                              'CIM_ClassModification'
                              'CIM_InstIndication'
                              'CIM_InstCreation'
                              'CIM_InstModification'
                              'CIM_InstDeletion'
                              'CIM_Error'
                              'MSFT_WmiError'
                              'MSFT_ExtendedStatus'
                              'WMI_Extension'
                            )

        $classnames = (Get-CimClass -Namespace $this.Namespace -CimSession $this.CimSession).CimClassName | Sort-Object

        foreach($classname in $classnames){
            if(-not ($classname.StartsWith('__')) -and ($classNamesToSkip -notcontains $classname)){
                $obj += [CMClass]::new($this.Namespace, $classname, $this.CimSession)
            }
        }

        return $obj
    }
}

[SHiPSProvider()]
class CMClass : SHiPSDirectory
{
    [Microsoft.Management.Infrastructure.CimSession]$CimSession = $null
    [string]$Namespace = $null
    [string]$Type = 'Class'

    CMClass([string]$namespace, [string]$name, [Microsoft.Management.Infrastructure.CimSession]$cimsession):base($name)
    {
        $this.Namespace = $namespace
        $this.CimSession = $cimsession
    }
     
    [object[]] GetChildItem()
    {
        try{
            return Get-CimInstance -ClassName $this.name -Namespace $this.Namespace -CimSession $this.Cimsession -ErrorAction Stop
        }

        catch [Microsoft.Management.Infrastructure.CimException]{
            if($_.FullyQualifiedErrorId -like 'HRESULT 0x80338102*'){
                Write-Verbose -Verbose -Message 'No instances for this class'
                return $null  
            }
            else{
                throw $_
            }
        } 
    }    
}

#region Cmdlets
function Get-CMSession{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )    
    [CMRoot]::Sessions | Where-Object {$_.ComputerName -eq $ComputerName}
}

function Connect-CIM{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        [pscredential]$Credential
    )
    if(Get-CMSession -ComputerName $ComputerName){
        Write-Verbose -Verbose -Message "Already connected to $ComputerName. Skipping ..."
    }
    else{
        ([CMRoot]::Sessions).Add((New-CimSession -ComputerName $ComputerName -Credential $Credential))        
    }
}

function Disconnect-CIM{
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    $sessionToRemove = Get-CMSession -ComputerName $ComputerName

    if($sessionToRemove){
        if(([CMRoot]::Sessions).Remove($sessionToRemove)){
            Remove-CimSession -CimSession $sessionToRemove -ErrorAction Stop
        }
    }
    else{
        Write-Verbose -Verbose -Message "No connection to $ComputerName. Skipping ..."        
    }
}

Export-ModuleMember -Function Connect-CIM,Disconnect-CIM
#endregion
