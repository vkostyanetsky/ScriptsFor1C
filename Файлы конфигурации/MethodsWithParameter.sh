# Скрипт ищет в файлах конфигурации методы (процедуры или функции), у которых есть параметр
# с определенным именем (ниже — параметр DecimalPlacesFor).

# Собственно поиск. Ищем и процедуры, и функции.
#
grep --with-filename '^[Procedure|Function].*(.*DecimalPlacesFor.*Export' */Ext/Module.bsl |

# Отрезаем все лишнее, чтобы на вывод ушли только названия модулей и найденных в них методов.
#
perl -pe 's/\/Ext\/Module.bsl:(Procedure|Function) /\./g;s/\(.*Export.*//g'