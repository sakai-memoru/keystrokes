function Global:Get-Logger{
    Param(
        [CmdletBinding()]
        [Parameter()][String]$Delimiter = " ",
        [Parameter()][String]$LogfilePath = "./apps.log",
        [Parameter()][String]$Encoding = "Default",
        [Parameter()][Switch]$NoDisplay
    )
    if (!(Test-Path -LiteralPath (Split-Path $LogfilePath -parent) -PathType container)) {
        New-Item $LogfilePath -type file -Force
    }
    $logger = @{}
    $logger.Set_Item('info', (Put-Log -Delimiter $Delimiter -LogfilePath $LogfilePath -Encoding $Encoding -NoDisplay $NoDisplay -Info))
    $logger.Set_Item('warn', (Put-Log -Delimiter $Delimiter -LogfilePath $LogfilePath -Encoding $Encoding -NoDisplay $NoDisplay -Warn))
    $logger.Set_Item('error', (Put-Log -Delimiter $Delimiter -LogfilePath $LogfilePath -Encoding $Encoding -NoDisplay $NoDisplay -Err))
    return $logger
}

function Global:Put-Log
{
    Param(
        [CmdletBinding()]
        [Parameter()][String]$Delimiter = " ",
        [Parameter()][String]$LogfilePath,
        [Parameter()][String]$Encoding,
        [Parameter()][bool]$NoDisplay,
        [Parameter()][Switch]$Info,
        [Parameter()][Switch]$Warn,
        [Parameter()][Switch]$Err
    )
    return {
        param([String]$msg = "")

        # Initialize variables
        $logparam = @("White", "INFO")
        if ($Warn)  { $logparam = @("Yellow", "WARN") }
        if ($Err) { $logparam = @("Red", "ERROR") }
        $txt = "[$(Get-Date -Format "yyyy/MM/dd HH:mm:ss")]${Delimiter}{0}${Delimiter}{1}" -f $logparam[1], $msg

        # Output Display
        if(!$NoDisplay) {
            Write-Host -ForegroundColor $logparam[0] $txt
        }
        # Output LogfilePath
        if($LogfilePath) {
            Write-Output $txt | Out-File -FilePath $LogfilePath -Append -Encoding $Encoding
        }
    }.GetNewClosure()
}
