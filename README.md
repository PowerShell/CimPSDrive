# CimPSDrive

The CimPSDrive provider allows easy navigation and discovery of CIM namespaces, including those in WMI.
CimPSDrive is a [SHiPS](https://github.com/PowerShell/SHiPS) based PowerShell provider and is based on [CIM cmdlets][cim].

![CimPSDrive in Action](media/intro.gif)

## Supported Platform

- PowerShell 5.1 (or later), which is shipped in Windows 10, Windows Server 2016, or [WMF 5.1][wmf51]

## Dependencies

[SHiPS](https://github.com/PowerShell/SHiPS) PowerShell module is required.

## Usage

- To start using the functionality of `CimPSDrive`, import the `CimPSDrive` module and create a PSDrive

    ```powershell
    Import-Module -Name CimPSDrive -Verbose
    New-PSDrive -Name CIM -PSProvider SHiPS -Root CIMPSDrive#CMRoot
    ```

- You can `cd` into a specific namespace and discover the classes
    ```powershell
    # List the classes under cimv2 namespace on local machine

    CIM:\localhost\cimv2> dir

    # Output will be similar to the following
        Directory: CIM:\localhost\cimv2

    Mode Type      Name
    ---- ----      ----
    +    Namespace Applications
    +    Namespace mdm
    +    Namespace power
    +    Namespace Security
    +    Namespace sms
    +    Namespace TerminalServices
    +    Class     CCM_ComputerSystemExtended
    +    Class     CCM_LogicalMemoryConfiguration
    +    Class     CCM_OperatingSystemExtended
    +    Class     CIM_Action
    ...
    ...
    ```

- Using `dir` or `ls`, you can find instances of a class

    ```powershell
    # Find the details about operating system
    CIM:\localhost\cimv2\Win32_OperatingSystem> dir

    # Output will be similar to the following
    SystemDirectory     Organization BuildNumber RegisteredUser SerialNumber            Version    PSComputerName
    ---------------     ------------ ----------- -------------- ------------            -------    --------------
    C:\WINDOWS\system32              16299       Windows User   00329-00000-00003-AA424 10.0.16299 localhost
    ```

- To connect to remote machines, use the `Connect-CIM` command
    > Note: This command only  works from within the PSDrive created above

    ```powershell
    # Connect to a remote machine
    Connect-CIM -ComputerName remoteMachine

    # Now you can see another entry under the PSDrive root
    CIM:\localhost\cimv2\Win32_OperatingSystem> dir /

        Directory: CIM:

    Mode Type Name
    ---- ---- ----
    +         localhost
    +         remoteMachine
    ```

    Now you can navigate the CIM hierarchy on remoteMachine as well.

- Use `Disconnect-CIM` command to disconnect from the remote machines
    > Note: This command only  works from within the PSDrive created above

## Installing CimPSDrive

- Download from the [PowerShell Gallery][psgallery]
- `git clone` https://github.com/PowerShell/CimPSDrive.git

## Developing and Contributing

Please follow [the PowerShell Contribution Guide][contribution] for how to contribute.

## Legal and Licensing

CimPSDrive is under the [MIT license][license].

[cim]: https://docs.microsoft.com/en-us/powershell/module/cimcmdlets
[wmf51]: https://www.microsoft.com/en-us/download/details.aspx?id=54616
[psgallery]: https://www.powershellgallery.com/packages/CimPSDrive
[contribution]: https://github.com/PowerShell/PowerShell/blob/master/.github/CONTRIBUTING.md
[license]: LICENSE.txt
