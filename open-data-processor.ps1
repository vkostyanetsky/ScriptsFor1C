# Открывает тонкий клиент 1С с указанным параметром и запускает определенную обработку.

$appPath = "C:\Program Files\1cv8\8.3.17.1989\bin\1cv8c.exe"    
$epfPath = "D:\UsefulDataProcessor.epf"
$outPath = "D:\UsefulDataProcessor Output.txt"
$lParams = "Option1;Option2"
    
$ArgumentsList =
    "ENTERPRISE",
    "/S `"localhost\21117-deleteme`"",
    "/N Administrator",
    "/P Password",
    "/Execute `"$epfPath`"",
    "/C `"$lParams`"",
    "/DisableStartupDialogs",
    "/out `"$outPath`" -NoTruncate"

Start-Process $appPath -ArgumentList $ArgumentsList -NoNewWindow -PassThru -Wait | Out-Null