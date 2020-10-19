# Скрипт анализирует технологический журнал и выводит топ ожиданий на блокировках. Блокировки группируются по области и контексту;
# для каждой выводится общее время ожидания, среднее время ожидания и количество установок. Сортировка — по общему времени ожидания.

# Читаем логи rphost'ов.
#
cat rphost_*/*.log |

# Скрипт разделяет лог по метке времени события и работает только с событиями TLOCK,
# у которых заполнено свойство WaitConnections (то есть, нас интересуют управляемые блокировки,
# которые реально ждали возможности быть установленными, а не просто потратили какое-то время
# на установку). Каждое событие блокировки разделяется по подстроке «,Context=»; таким образом,
# в первом поле у нас будет строка события до контекста, во втором поле — только контекст.
#
# Из первого поля нам нужна продолжительность события TLOCK (т.е. время ожидания на блокировке).
# Его можно получить, найдя позицию первой запятой; всё до неё и есть длительность, так как
# время начала события мы уже удалили при разделении записей.
#
# Также в первом поле есть область блокировки. Чтобы получить её, отрезаем строку до значения области,
# а потом снова ищем первую запятую. Строка до неё — область.
#
# Во втором поле нас интересует только контекст. Сначала отрезаем символы перевода строки с конца,
# чтобы не возникло проблем при группировке последней записи в файле, потом заменяем переводы строк
# на подстроку <LF> (если этого не сделать — сортировать не получится). Проверяем, что в итоге
# контекст вообще есть (его в событии может не быть вовсе — например, если он выведен отдельным
# событием Context). В общем, если контекст есть — просто добавляем его к значению области.
#
# Основное тело скрипта делится на две части; первая собирает данные в массивы DurationByRegions
# и QuantityByRegions. Первый хранит общую длительность ожиданий на блокировках,
# второй — количество их установк. Ключи каждого массива — область блокировки и
# если возможно, контекст.
#
# Завершающая часть скрипта считает и выводит общую и среднюю продолжительность ожиданий в секундах.
#
gawk -F',Context=' -vRS="[0-9]+:[0-9]+.[0-9]+-" '

function StringBeforeComma(StringWithComma)
{
    return substr(StringWithComma, 0, index(StringWithComma, ",") - 1);
}

function RegionsAndContext(StringBeforeContext, StringAfterContext)
{
    gsub(".*,Regions=", "", StringBeforeContext);

    Result = StringBeforeComma(StringBeforeContext);
       
    gsub("\n+$", "", StringAfterContext);
    gsub("\n", "<LF>", StringAfterContext);
       
    if ( StringAfterContext !~ "^$" ) {
        Result = Result "<LF>" StringAfterContext;
    }

    return Result;
}

{
    if ( $0 ~ ".*,TLOCK,.*,WaitConnections=[0-9]+.*" ) {

        Duration = StringBeforeComma($1);
        Grouping = RegionsAndContext($1, $2);

        DurationByRegions[Grouping] += Duration;
        QuantityByRegions[Grouping] += 1;

    }
};

END {
    for (Grouping in DurationByRegions) {
    
        totalQuantity   = QuantityByRegions[Grouping];
        totalDuration   = DurationByRegions[Grouping] / 1000000;
        averageDuration = DurationByRegions[Grouping] / QuantityByRegions[Grouping] / 1000000;
    
        printf "%.3f seconds total, %.3f seconds on average, %d locks<LF>%s<LF>\n", totalDuration, averageDuration, totalQuantity, Grouping;
        
    }
}
' |

# Сортировка и отсечение первой сотни результатов.
#
sort -rn |
head -n 100 |

# Мы заменяли переводы строк на подстроку <LF>, чтобы в дальнейшем результат можно было отсортировать утилитой sort.
# Поскольку сортировка проделана, можно сделать обратную замену — тогда результат будет удобнее читать.
#
sed -r "s/<LF>/\n/g" > TopLocks.txt