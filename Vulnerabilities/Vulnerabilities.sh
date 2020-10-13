# Поиск адресов электронной почты в текстах программных модулей.
#
# Логика: ищем все BSL-файлы, а в них — e-mail по шаблону.
# Минусы: находятся e-mail'ы разработчиков.

find . -name "*.bsl" -print0 | xargs -0 egrep "[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+" > InlineEmails.txt

# Поиск URL-адресов в текстах программных модулей.
#
# Логика: ищем все BSL-файлы, а в них — URL по шаблону.
# Минусы: под регулярку попадают пространства XDTO-пакетов.

find . -name "*.bsl" -print0 | xargs -0 egrep "(ftp|http|https):\/\/[^ \"]+" > InlineURLs.txt

# Поиск IP-адресов в текстах программных модулей.
#
# Логика: ищем все BSL-файлы, а в них — IP по шаблону.
# Минусы: под регулярку попадают версии конфигурации.

find . -name "*.bsl" -print0 | xargs -0 egrep "([0-9]{1,3}[\.]){3}[0-9]{1,3}" > InlineIPs.txt

# Поиск ролей с правом интерактивного удаления.

grep -A1 "<name>InteractiveDelete</name>" Roles/*/Ext/Rights.xml | grep "<value>true</value>" > InteractiveDelete.txt