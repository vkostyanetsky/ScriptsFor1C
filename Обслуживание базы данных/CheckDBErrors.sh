# Поиск ошибок в выводе команды DBCC CHECKDB().
#
# Задачи:
#
# 1. Ищет все объекты с ошибками и помещает в файл DBCC CHECKDB Errors.txt;
# 2. Имена таблиц с ошибками помещает в файл DBCC CHECKDB Tables.txt.
#
# Удобен для быстрого анализа поврежденной базы без скроллинга лога: можно быстро оценить,
# какие объекты были повреждены и каков характер повреждений. Список таблиц можно вставить
# в обработку поиска метаданных и сопоставить его в объектами метаданных конфигурации.
#

cat "DBCC CHECKDB.txt" |

gawk -F'\n' -vRS='DBCC results for ' '{
    
    # Если следующая строка начинается с «There are», то ошибок для объекта нет.
    #
    if ($2 !~ "^There are .*") 
    {
        IsTable = match($1, /^._.*\./) != 0
        
        if (IsTable) {
        
            # Отрезаем от имени таблицы кавычки и точку в конце.
            #
            Table = substr($1, 2, length($1) - 3)

            Tables[Table] = Table
        
        }
                
        print $0 "\n" > "DBCC CHECKDB Errors.txt"
    }
};   

END {

    asort(Tables)

    for (Table in Tables) {
        print Tables[Table] > "DBCC CHECKDB Tables.txt"
    }
    
}'