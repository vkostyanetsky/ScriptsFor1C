# Скрипт делает POST-запрос к HTTP-сервису InternalAPI,
# вызывая метод UpdateUser с параметрами UserLogin и UserPassword.

$URL    = "http://localhost/DevFBERP"   # Адрес публикации
$user   = 'Administrator'               # Логин пользователя
$pass   = ''                            # Пароль пользователя

$apiUrl         = $url + "/hs/InternalAPI"
$pair           = "$($user):$($pass)"
$encodedCreds   = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"

$answer = Invoke-WebRequest -uri "$apiUrl/UpdateUser" `
-Method Post `
-headers @{'Authorization' = $basicAuthValue; 'Content-Type'= 'application/json'} `
-body "{'UserLogin':'Cashier', 'UserPassword':'1234'}"

$result = ConvertFrom-Json -InputObject $answer
    
$result