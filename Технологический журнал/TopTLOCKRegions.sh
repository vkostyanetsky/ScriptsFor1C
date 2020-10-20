# Топ ожиданий на блокировках. Блокировки группируются по области; для каждой выводится общее время ожидания,
# среднее время ожидания и количество установок. Сортировка — по общему времени ожидания.

cat rphost_*/*.log |

# Фильтруем только TLOCK'и, у которых заполнено свойство WaitConnections (т.е. платформа реально ждала возможности установить
# управляемую блокировку, а не просто потратила какое-то время на её создание).
#
grep -E ',TLOCK,.*WaitConnections=[0-9]+' |

# Вырезаем из информации о событии все данные, кроме его продолжительности и областей.
#
sed -r 's/.*-([0-9]+),TLOCK,.*Regions=(.*),Locks=.*/\1 \2/' |

# Группируем по области и считаем нужные показатели.
#
gawk '{

    DurationByRegions[$2] += $1;
    QuantityByRegions[$2] += 1;    

}; END {

    for (Regions in DurationByRegions) {
    
        totalQuantity   = QuantityByRegions[Regions];
        totalDuration   = DurationByRegions[Regions] / 1000000;
        averageDuration = DurationByRegions[Regions] / QuantityByRegions[Regions] / 1000000;
    
        printf "%.3f seconds total, %.3f seconds on average, %d locks %s\n", totalDuration, averageDuration, totalQuantity, Regions;
    
    }

}' |

# Сортируем и выводим первые сто результатов.
#
sort -rn |
head -n 100 > TopTLOCKRegions.txt