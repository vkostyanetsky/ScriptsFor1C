# Топ длительных запросов к MSSQL.
# 
# Запросы группируются по тексту (поле Sql) и контексту (поле Context). Если текст или контекст
# отсутствуют в записи о событии, группировка будет по тем данным, что есть — например, только
# по запросу или только по контексту. Если нет ни запроса, ни контекста, группировка будет
# выполнена по пустой строке.
#
# Для каждого выводится суммарное время выполнения, среднее и максимальное, а также общее число
# выполнений. Сортировка — по суммарному времени, от большего к меньшему.
#

cat */*.log |

# Удаляем из потока данных UTF-8 BOM.
#
perl -pe 's/\xef\xbb\xbf//g' |

# Сразу удаляем строки с параметрами запросов — они помешают нормальной группировке.
# Вообще это логичнее делать внутри скрипта gawk, но я не придумал, как.
#
sed -r "/^p_[0-9]+:/d" |

# Утилита gawk разделяет лог по метке времени события и выполняет переданный ей скрипт.
#
gawk -vRS='[0-9]+:[0-9]+.[0-9]+-' '

function GetDuration(Input) {

    # Мы разделили события по времени их начала, поэтому набор цифр до запятой — это продолжительность события.    
    #
    return int(substr(Input, 0, index(Input, ",") - 1));
    
}

function GetGroup(Input) {

    # Определим, какие составляющие группировки есть в тексте события. Нас интересует либо Sql,
    # либо Context, а лучше и то, и другое.

    if (index(Input, "Sql=") != 0) {
           
        Result = Input;
           
        gsub("^.*Sql=", "Sql=", Result);
        
    }
    else if (index(Input, "Context=") != 0) {
                        
        Result = Input;
                        
        gsub("^.*Context=", "Context=", Result);
          
    }
    else {
        
        # Если в событии нет ни текста запроса, ни контекста выполнения —
        # группируем по пустой строке.
        #
        Result = "";
            
    }
    
    if (Result != "") {
    
        gsub("\n+$",                                "",     Result); # удалим двойные переводы строк
        gsub("\n",                                  "<LF>", Result); # заменим переводы строк на <LF>
        gsub("#tt[0-9]+",                           "#tt",  Result); # нормализуем имена временных таблиц
        gsub("Rows=[0-9]+,RowsAffected=[0-9]+,",    "",     Result); # удалим данные, не нужные для анализа    
    
    }
    
    return Result;

}

{
    # Отбираем только события DBMSSQL.
    #    
    if ( $0 ~ "^[0-9]+,DBMSSQL.*" ) {

        Duration    = GetDuration($0);
        Group       = GetGroup($0);

        QueriesDuration[Group] += Duration;
        QueriesExecuted[Group] += 1;
        
        if (Duration > MaxQueriesDuration[Group]) {
            MaxQueriesDuration[Group] = Duration;
        }
        
    }
};

END {

    for (Group in QueriesDuration) {
    
        executedTotal   = QueriesExecuted[Group];
        durationMax     = MaxQueriesDuration[Group] / 1000000;
        durationTotal   = QueriesDuration[Group] / 1000000;
        durationAverage = QueriesDuration[Group] / QueriesExecuted[Group] / 1000000;
        
        printf "%.3f seconds total, %.3f seconds on average, %.3f seconds at maximum, %d executions<LF>%s<LF>\n", durationTotal, durationAverage, durationMax, executedTotal, Group;
        
    }
    
}
' |

sort -rn |
head -n 1000 |

# Мы заменяли переводы строк на подстроку <LF>, чтобы результат можно было отсортировать (sort) и усечь (head).
# Теперь можно сделать обратную замену — тогда результат будет удобнее читать.
#
sed -r "s/<LF>/\n/g" > LongestQueries.txt