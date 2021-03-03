# Скрипт делает GET-запрос к HTTP-сервису InternalAPI,
# вызывая метод User с параметром UserLogin.

$URL    = "http://localhost/DevFBERP"   # Адрес публикации
$user   = 'Administrator'               # Логин пользователя
$pass   = ''                            # Пароль пользователя

$apiUrl         = $url + "/hs/InternalAPI"
$pair           = "$($user):$($pass)"
$encodedCreds   = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"

Invoke-WebRequest -uri "$apiUrl/User?UserLogin=Administrator" `
-Method Get `
-headers @{'Authorization' = $basicAuthValue; 'Content-Type'= 'application/json'}