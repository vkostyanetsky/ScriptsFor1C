# Список описаний исключений с группировкой по наименованию исключения.
#

cat rphost_*/*.log | 

# Удаляем из потока данных UTF-8 BOM.
#
perl -pe 's/\xef\xbb\xbf//g' |

# Теперь нам нужно найти события исключений (EXCP), прочитать из них описание (Descr) и определить, сколько раз
# среди исключений попадается каждое описание. С этой задачей хорошо справляется gawk. 
#
# Установим настройки. Каждое событие начинается с времени и продолжительности (например, 14:55.636001-1).
# Сделаем такую подстроку разделитем записей. Теперь каждая запись будет содержать событие полностью (со всеми 
# переводами строк и другими спецсимволами).
# 
# Разделителем полей поставим запятую, но по факту это не пригодится: нам нужно анализировать два поля события,
# Exception и Descr. Последний всегда идет в конце события, а вот положение Exception может разниться в зависимости
# от конкретного исключения.
#
# Скрипт работает в два этапа. На первом мы формируем массив двойной вложенности, ключи которого — значения Exception.
# Значения массива — массивы с ключом, равным описанию, и значением, равным количеством нахождения этого описания.
#
gawk -F',' -vRS='[0-9]+:[0-9]+.[0-9]+-[0-9]+,' '

function GetException(Input) {

    gsub("^.*Exception=", "", Input);
    gsub(",Descr=.*$", "", Input);
    
    return Input;
    
}

function GetDescription(Input) {

    gsub("^.*Descr=", "", Input);
    
    return Input;
    
}

{  
    if ( $0 ~ "^EXCP,.*" ) {
                
        Exception   = GetException($0);
        Description = GetDescription($0);
        
        ExceptionDescriptions[Exception][Description] += 1;
        
        if (Exception ~ "SessionID=1") {
            print $0;
        }
                        
    }
};

END {
    for (Exception in ExceptionDescriptions) {
    
        print "---";
        print "EXCEPTION: " Exception;
        print "---\n";
    
        for (Description in ExceptionDescriptions[Exception]) {
        
            EventsNumber = ExceptionDescriptions[Exception][Description]
        
            print "Description (" EventsNumber " events)\n";
            print Description;            
            
        }
               
    }
    
}' > ExceptionDescriptions.txt