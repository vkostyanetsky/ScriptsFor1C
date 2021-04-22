# Поиск попыток наложений управляемых блокировок по номеру соединения и области блокировки.
#
# Скрипт принимает два параметра: 
#   1. номер соединения (t:connectID)
#   2. область наложения блокировки (Regions)
#
# Пример вызова:
#   bash LocksByConnectIDAndRegions.sh 80283 InfoRg55705
#

# Для удобства дальнейшей работы добавим в вывод имена файлов и номера строк.
# Привычную утилиту cat невозможно заставить сделать это, поэтому придется
# пойти на жульничество: используем поиск любого символа с помощью grep,
# которая как раз умеет то, что нам нужно.
#
# Есть более адекватные способы добиться нужного результата, но этот, пожалуй,
# самый короткий из них.
#
grep --with-filename --line-number . rphost_*/*.log |

# Во-первых, удалим из потока данных BOM. Во-вторых, в дальнейшем мы будем работать
# с отдельными событиями и нам потребуется их сортировать. Во-вторых, переводы строк
# помешают использовать утилиту sort, так что заменим их на подстроку <AWK LB>.
#
perl -pe 's/\xef\xbb\xbf//g; s/\r\n/<AWK LB>/g' |

# Найдем в потоке события. Для этого отловим строго конкретную последовательность
# символов: имя файла, двоеточие, номер строки, двоеточие (это все было добавлено
# grep'ом), а потом — стандартная строка начала события в ТЖ. Перед каждым найденным
# результатом добавим маркер начала события <AWK RS>.
#
# Помимо этого, вытащим дату/время события и вынесем его в начало строки:
# тогда sort сможет с этим работать.
#
perl -pe 's/(rphost_[0-9]+\/([0-9]+)\.log:[0-9]+:([0-9]+):([0-9]+\.[0-9]+)-[0-9]+)/<AWK RS>\2\3\4 \1/g' |

# Разделим поток на отдельные события с помощью маркера <AWK RS> и проанализируем:
# подходят эти события под условия из параметров скрипта или нет. Если подходят —
# отдельными строками для каждого выведем поля Locks и alreadyLocked (если есть).
#
gawk -vCONNECTID=$1 -vREGIONS=$2 -vLB='<AWK LB>' -vRS='<AWK RS>' '

function GetFieldValue(FieldValues, BeginsWith)
{
    Result = "";
    
    BeginsWithLength = length(BeginsWith);
    
    for (FieldValuesKey in FieldValues) {
           
        Value = FieldValues[FieldValuesKey];
           
        ValueBeginsWith = substr(Value, 1, BeginsWithLength);
        
        if (ValueBeginsWith == BeginsWith) {
            Result = Value;
            break;
        }
            
    }
    
    return Result;
}

{
    if ( $0 ~ ".*TLOCK,.*,t:connectID=" CONNECTID ",.*,Regions=" REGIONS ".*" ) 
    {    
        split($0, FieldValues, ",");
    
        Locks           = GetFieldValue(FieldValues, "Locks=");
        alreadyLocked   = GetFieldValue(FieldValues, "alreadyLocked=");        
    
        print $0 "\t" Locks LB "\t" alreadyLocked LB;
    }
}' |

# Сортируем получившиеся события по времени — от самых ранних к самым поздним.
#
sort --ignore-leading-blanks --numeric-sort |

# Заменяем <AWK LB> обратно на переводы строк, чтобы результат был похож на исходный ТЖ.
#
perl -pe 's/<AWK LB>/\r\n/g' > LocksByConnectIDAndRegions_$1_$2.txt