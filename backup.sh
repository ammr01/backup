#!/bin/bash
# Author : user
# OS : Debian 12 x86_64
# Date : 06-Jan-2024
# Project Name : backup3

args=()
abs_dirs_list=()
dirs_list=()
list=()


show_help(){
    echo "Usage: $0 <directories/files to backup (use absolute path, and seperate by space)> -d <backup destination directory> "
}


print_file(){
    if [ -f $1 ]; then
        echo $1
    else
        echo ""
    fi
}


print_dir(){
    if [ -d $1 ]; then
        echo $1
    else
        echo `print_file $1`
    fi
}


get_time(){
    /usr/bin/date +%d-%m-%Y-%H-%M
}


add(){
    if [ "$#" -lt 1 ]; then
        {>&2 echo "Error : Few arguments to add() function."; return 2;}
    elif [ "$#" -gt 1 ]; then
        {>&2 echo "Error : Many arguments to add() function."; return 2;}
    fi

    args+=("$1")
    if [ -z $1 ]; then
        return 3
    elif [ -d $1 ] || [ -f $1 ] ; then
        abs_dirs_list+=("$1")
        dirs_list+=("`basename $1`")
    else
        return 4
    fi
    
}



compare_arrays() {
    # Takes two arrays as arguments
    # Returns 0 if two arrays are equal, and returns 1 if array2
    # is a subset of array1, and returns 2 if array1 is a subset
    # of array2, and returns 3 if arrays are not a subset of each other

    if [ "$#" -ne 2 ]; then
        echo "Error: Invalid argument number to compare_arrays() function!" >&2
        return 5
    fi

    local array1=("${!1}")
    local array2=("${!2}")

    if [ ${#array1[@]} -eq  0 ] && [ ${#array2[@]} -eq  0 ]; then
        return 0;
    elif [ ${#array1[@]} -ne  0 ] && [ ${#array2[@]} -eq  0 ]; then
        return 1;
    elif [ ${#array1[@]} -eq  0 ] && [ ${#array2[@]} -ne  0 ]; then
        return 2;
    fi
    local fsubs=true  # first is a subset of second
    local ssubf=true  # second is a subset of first

    for array1_element in "${array1[@]}"; do
    local count=0
        for array2_element in "${array2[@]}"; do
            ((count++))
            if [ "$array2_element" == "$array1_element" ]; then
                echo " ==="
                break
            elif [ "$array2_element" != "$array1_element" ] && [ $count -eq ${#array2[@]} ]; then
                fsubs=false
            fi
            echo ""
        done
    done

    for array2_element in "${array2[@]}"; do
        count=0
        for array1_element in "${array1[@]}"; do
            ((count++))
            if [ "$array1_element" == "$array2_element" ]; then
                echo " ==="
                break
            elif [ "$array1_element" != "$array2_element" ] && [ $count -eq ${#array1[@]} ] ; then
                ssubf=false
            fi
            echo ""

        done
    done

       

    if [ "$fsubs" = true ] && [ "$ssubf" = true ]; then
        return 0
    elif [ "$fsubs" = false ] && [ "$ssubf" = true ]; then
        return 1
    elif [ "$fsubs" = true ] && [ "$ssubf" = false ]; then
        return 2
    elif [ "$fsubs" = false ] && [ "$ssubf" = false ]; then
        return 3
    else
        return 4
    fi
}

extract_names(){
    # takes directory name and prints all file/subdir names inside 
    # stores the output into list, using convert_to_array
    # the directory, for example:
    # extract_names /home/user/Desktop
    # /home/user/Desktop/notes.txt
    # /home/user/Desktop/koko/koko
    if [ "$#" -ne 1 ]; then
        echo "Error: Invalid argument number to extract_names() function!" >&2
        return 2
    fi
    local array=("${!1}")
    for i in "${array[@]}";do
        find $i -type d,f >> /tmp/backup.tmp ## replace $1 with a list
    done
    local status_code=$?
    if [ $status_code -ne 0 ]; then
        return $status_code
    elif [ $status_code -eq 0 ]; then
     local output="`sort /tmp/backup.tmp | uniq`"
        rm /tmp/backup.tmp
        convert_to_arrayln "$output"
        remove_fs list[@]
        append_fs list[@]
        return $status_code
    fi
    return $status_code
}

convert_to_array() {
    # Converts strings to array, elements are separated by separator
    # Stores the output in the global array $list
    # Returns 0 if no errors occurred, otherwise returns 2
    # $1 is the string, $2 is the separator

    if [ "$#" -ne 2 ]; then
        echo "Error: Invalid argument number to convert_to_array() function!" >&2
        return 2
    fi

    local input="$1"
    local separator="$2"
    list=()
    if [ "${#separator}" -ne 1 ]; then
        echo "Error: Separator must be a single character." >&2
        return 1
    fi

    
    if [ -z "$input" ]; then
        echo "Error: Input string is empty." >&2
        return 3
    fi

    
    field_count=$(echo "$input" | awk -F"$separator" '{print NF}')
    for ((i = 1; i <= field_count; i++)); do
        list+=( "$(echo "$input" | cut -d "$separator" -f $i)" )
    done
    return 0
}

remove_fs(){
    # takes list and remove leading forward slash (/) (fs), 
    # from all the elements
    if [ "$#" -ne 1 ]; then
        echo "Error: Invalid argument number to remove_fs() function!" >&2
        return 2
    fi
    local array=("${!1}")
    list=()
    for i in "${array[@]}";do
        list+=( "${i#/}" )
    done
}
append_fs(){
    # takes list and append forward slash (/) (fs), 
    # to elements that is a valid directory
    if [ "$#" -ne 1 ]; then
        echo "Error: Invalid argument number to append_fs() function!" >&2
        return 2
    fi
    local array=("${!1}")
    list=()
    for i in ${array[@]};do
        local d="${i#/}"
        local d="/$d"
        if [ -d "$d" ]; then
            list+=( "${i%/}/" )
        else
            list+=( "${i%/}" )
        fi
    done
}


convert_to_arrayln() {
    # Converts strings to array, each line is a element
    # Stores the output in the global array $list
    # Returns 0 if no errors occurred, otherwise returns 2
    # $1 is the string

    if [ "$#" -ne 1 ]; then
        echo "Error: Invalid argument number to convert_to_arrayln() function!" >&2
        return 2
    fi

    local input="$1"
    list=()

    
    if [ -z "$input" ]; then
        echo "Error: Input string is empty." >&2
        return 3
    fi

    
    local line_count=$(echo "$input" | wc -l )
    for ((i = 1; i <= line_count; i++)); do
        list+=( "$(echo "$input" | awk "NR == $i")" )
    done
    return 0
}



create_directory() {
            
    if [ "$#" -lt 1 ]; then
        {>&2 echo "Error : Few arguments to create_directory() function."; return 2;}
    elif [ "$#" -gt 1 ]; then
        {>&2 echo "Error : Many arguments to create_directory() function."; return 2;}    
    fi
    directory=$1
    #try to create or open the Directory
    if [ -d "$directory" ]; then
        cd "$directory" || {>&2 echo "Error : Cannot change to directory : $directory"; return 1;}
    else
        mkdir -p "$directory" || {>&2 echo "Error : Cannot create new directory : $directory"; return 1;}
        cd "$directory"
    fi

}


getdirs() {
    array_length=${#dirs_list[@]}
    for ((i=0; i<array_length; i++)); do
        echo -n "${dirs_list[$i]}"
        if [ $i -ne $((array_length - 1)) ]; then
            echo -n "-"
        fi
    done
    echo  # Add a newline at the end
}


create_tar(){
    /usr/bin/tar fc $backup_file --use-compress-program=pigz $tar_arguments $dirs  
    return $?
}



archive(){
    
    if [ $# -lt 2 ]; then
        echo "Error: Few arguments to archive() function!" >&2 ; return 1
    fi

    local backup_dir=$1
    shift
    local tar_arguments=$1
    shift
    
    create_directory $backup_dir || return $?
    # backup_file="$backup_dir/backup[`getdirs`][`/usr/bin/date +%d-%m-%Y-%H-%M``].tar.gz"
    local backup_file="$backup_dir/backup[`getdirs`][`get_time`].tar.gz"
                                  #^^^compare^ ^ignore_compare^
    
    local dirs=""

    for arg in $@; do
        dirs=" $dirs`print_dir $arg` "   
    done
    
    ## check for *[file1-file2]* tar file
  
    created=1
    for file in * ;do
        if [ $file == "*" ]; then
            create_tar || return $?
            break
        fi
        local tar_res="`tar tf $file | sort | uniq`"
        convert_to_arrayln "$tar_res"
        local tar_list=("${list[@]}")
        extract_names abs_dirs_list[@] || return $?
        extracted_dirs_list=("${list[@]}")
        compare_arrays tar_list[@]  extracted_dirs_list[@]
        result=$?
        if [ $result -eq 0 ] || [ $result -eq 2 ]; then
            if [ $created -eq 1 ]; then
                create_tar || return $?
                created=0
            fi
            if [[ "`basename $file`" != "`basename $backup_file`" ]]; then
                rm $file || return $?
            fi
        else            
            create_tar  || return $?
        fi
    done   

}




if [ $# -lt 1 ]; then
    show_help; exit 1
fi

directory="~/backup"

while [ $# -gt 0 ]; do
    case $1 in 
    -h|--help)
        show_help; exit 0
    ;;
    --tar_arguments)
        if [ -n "$2" ]; then        
            tar_arguments="$2"
            shift 2
        else
            >&2 echo "Error: --tar_arguments option requires argument."
            exit 1
        fi
    ;;
    
    -d|--directory|--destination)
        if [ -n "$2" ]; then        
            destination=$2
            shift 2
        else
            >&2 echo "Error: --destination option requires argument."
            exit 1
        fi
    ;;
    *)
        add $1 || exit $?
        shift
    ;;
    esac
done




archive "$destination" "$tar_arguments" ${abs_dirs_list[@]} || exit $?


echo "archived successfully!"


