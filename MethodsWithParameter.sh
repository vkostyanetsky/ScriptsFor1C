# Пример поиска в выгрузке конфигурации метода (процедуры или функции), у которого есть параметр DecimalPlacesFor.

# Собственно поиск.
grep --with-filename '^[Procedure|Function].*(.*DecimalPlacesFor.*Export' */Ext/Module.bsl |

# Отрезаем все лишнее, чтобы на вывод ушли только названия модулей и найденных в них методов.
perl -pe 's/\/Ext\/Module.bsl:(Procedure|Function) /\./g;s/\(.*Export.*//g'