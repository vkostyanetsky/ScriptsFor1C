# Топ длительных запросов к MSSQL.
# 
# Запросы группируются по тексту и его контексту. Для каждого выводится общее время выполнения,
# среднее время выполнение и количество выполнений. Сортировка — по общему времени.

cat rphost_*/*.log |

# Удаляем из потока данных UTF-8 BOM.
#
perl -pe 's/\xef\xbb\xbf//g' |

# Сразу удаляем строки с параметрами запросов — они помешают нормальной группировке.
# Вообще это логичнее делать внутри скрипта gawk, но я не придумал, как.
#
sed -r "/^p_[0-9]+:/d" |

# Скрипт разделяет лог по метке времени события и работает только с событиями DBMSSQL.
# Каждое событие разделяется по подстроке «Sql=»; таким образом, в первом поле у нас будет
# строка события до текста запроса, во втором поле — Sql, Rows, RowsAffected и Context.
#
# Из первого поля нам нужна только продолжительность события (т.е. время выполнения запроса).
# Его можно получить через split(), который разделит строку по запятым. Строка до первой запятой
# и есть длительность, так как время начала события мы уже удалили при разделении записей.
#
# Во втором поле нас интересует только текст запроса и контекст. Поэтому остальные два параметрам
# мы удаляем, а также заменяем имена временных таблиц на одно универсальное (улучшит группировку)
# и заменяем переводы строк на подстроку <LF> (если этого не сделать — сортировать будет неудобно).
#
# Скрипт делится на две части; первая собирает данные в массивы QueriesDuration и QueriesExecuted.
# Первый хранит общую длительность запросов, второй — количество их выполнений. Ключи каждого — 
# текст запроса и его контекст.
#
# Завершающая часть скрипта считает общую и среднюю продолжительность запросов в секундах, 
# форматирует и выводит.
#
gawk -F'Sql=' -vRS='[0-9]+:[0-9]+.[0-9]+-' '

function StringBeforeComma(StringWithComma)
{
    return substr(StringWithComma, 0, index(StringWithComma, ",") - 1);
}

function SqlAndContext(StringAfterSql)
{
    gsub("\n+$", "", StringAfterSql);
    gsub("\n", "<LF>", StringAfterSql);
    gsub("#tt[0-9]+", "#tt", StringAfterSql);
    gsub("Rows=[0-9]+,RowsAffected=[0-9]+,", "", StringAfterSql);

    return StringAfterSql;
}

{
    if ( $1 ~ "^.*,DBMSSQL.*" ) {

        Duration = StringBeforeComma($1);
        Grouping = SqlAndContext($2);

        QueriesDuration[Grouping] += Duration;
        QueriesExecuted[Grouping] += 1;
    }
};

END {
    for (Query in QueriesDuration) {
    
        executedTotal   = QueriesExecuted[Query];
        durationTotal   = QueriesDuration[Query] / 1000000;
        durationAverage = QueriesDuration[Query] / QueriesExecuted[Query] / 1000000;
        
        printf "%.3f seconds total, %.3f seconds on average, %d executions<LF>%s<LF>\n", durationTotal, durationAverage, executedTotal, Query;
        
    }
}
' |

sort -rn |
head -n 100 |

# Мы заменяли переводы строк на подстроку <LF>, чтобы результат можно было отсортировать (sort) и усечь (head).
# Теперь можно сделать обратную замену — тогда результат будет удобнее читать.
#
sed -r "s/<LF>/\n/g" > LongestQueries.txt