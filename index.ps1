$project_name = split-path $PWD.path -leaf
$main = ".\$project_name.ps1"


.\KeypressValueToREG.exe
.\ShowKeypressValue.exe

. $main

