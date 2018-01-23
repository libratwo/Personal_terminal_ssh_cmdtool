#!/usr/bin/env sh

DBFILE=~/.ssh_servers.dat
#MINTTYRC=~/.minttyrc_ssh
TBNAME=ssh_server_list
DFTSSHPORT=22

# init database & table
function initdb {
    sqlite3 $DBFILE "create table $TBNAME (id number(2),\
        alias char(12),\
        server char(64),\
        port number(5),\
        encoding char(8),\
        passwd char(20));"
    sqlite3 $DBFILE "create unique index u_idx_ssh_id on $TBNAME (id);"
    sqlite3 $DBFILE "create unique index u_idx_ssh_name on $TBNAME (alias);"
}

function listservers {
    #echo "# id  alias-name   server"
    # -full with all cols output
    if [ $# -eq 1 -a "x$1" = "x-full" ];then
        sqlite3 -header $DBFILE <<EOF
.mode column
.width -2 12 20 5 8 12
select id,alias,server,port,encoding,passwd from $TBNAME order by id;
EOF
        echo "=============================================================="
    else
        sqlite3 -header $DBFILE <<EOF
.mode column
.width -2 18 28
select id,alias,server from $TBNAME order by id;
EOF
        echo "===================================================="
    fi
}

function addserver {
    # var   1 newId
    #       2 alias
    #       3 server:port
    #       4 encoding
    #       5 passwd
    offset=$(expr index "$3" ":")
    if [ $offset -ne 0 ];then
        # port set
        local _server=$(echo $3|cut -d':' -f1)
        local _port=$(echo $3|cut -d':' -f2)
    else
        local _server=$3
        local _port=$DFTSSHPORT
    fi
    sqlite3 $DBFILE "insert into $TBNAME values($1,'$2','$_server','$_port','$4','$5');"
}

function upserver {
    # var   1 oldId
    #       2 newId
    #       3 alias
    #       4 server
    #       5 encoding
    #       6 passwd
    offset=$(expr index "$4" ":")
    if [ $offset -ne 0 ];then
        # port set
        local _server=$(echo $4|cut -d':' -f1)
        local _port=$(echo $4|cut -d':' -f2)
    else
        local _server=$4
        local _port=$DFTSSHPORT
    fi
    sqlite3 $DBFILE "update $TBNAME set id=$2, \
                                        alias='$3', \
                                        server='$_server', \
                                        port=$_port, \
                                        encoding='$5', \
                                        passwd='$6' \
                                    where id=$1;"
}

function delserver {
    # var   1 Id
    sqlite3 $DBFILE "delete from $TBNAME where id=$1;"
}

function pickbyid {
    # var   1 Id
    sqlite3 -separator ' ' $DBFILE "select id,alias,server,port,encoding,passwd from $TBNAME where id=$1;"
}

function pickbyname {
    # var   1 alias
    sqlite3 -separator ' ' $DBFILE "select id,alias,server,port,encoding,passwd from $TBNAME where alias like '%$1%';"
}

#######################################################
id=0
name=''
server=''
port=$DFTSSHPORT
encoding=''
passwd=''

#ssh cmd
#mintty -c ~/.minttyrc_ssh -t 'name' -e sshpass -p 'passwd' ssh 'server'

function readparam {
    # shift args
    id=$1
    name=$2
    server=$3
    port=$4
    encoding=$5
    passwd=$6
}

function sshcmd {
    # var   1 encoding
    #       2 alias
    #       3 passwd
    #       4 server
    #       5 port
    #if [ "$1" = "UTF-8" ];then
    #    cmdpre="mintty -t $2-[$4] -e"
    #else
    #    cmdpre="mintty -c ~/.minttyrc_ssh -t $2-[$4] -e"
    #fi

    minttyopt="-o Charset=$1 -o BackspaceSendsBS=yes -o ThemeFile=base16-pop.minttyrc"
    cmdpre="mintty $minttyopt -t $2-[$4] -e "
    sshopt="-o StrictHostKeyChecking=no "
    if [ "x$port" = "x$DFTSSHPORT" ];then
        sshcomm="sshpass -p $3 ssh $sshopt $4"
    else
        sshcomm="sshpass -p $3 ssh $sshopt -p $5 $4"
    fi

    echo "Establish to SSH: $2 [$4] .."
    nohup $cmdpre $sshcomm &>/dev/null &
}

function sftpcmd {
    #var    1 alias
    #       2 passwd
    #       3 server
    #       4 port
    sshopt="-o StrictHostKeyChecking=no "
    if [ "x$port" = "x$DFTSSHPORT" ];then
        sftpcomm="sshpass -p $2 sftp $sshopt $3"
    else
        sftpcomm="sshpass -p $2 sftp $sshopt -P $4 $3"
    fi

    echo "Establish to SFTP: $1 [$3] .."
    $sftpcomm
}

# main use of function
function dssh {
    if [ $# -lt 1 ];then
        #list all
        listservers
        return
    fi

    if [ "x$1" = "x-f" ];then
        listservers -full
        return
    fi

    isid=$(expr "$1" : "^[0-9]")
    if [ $isid -eq 1 ];then
        # by Id
        echo "pick server by id: $1"
        servconf=$(pickbyid $1)
        if [ -n "$servconf" ];then
            readparam $servconf
        fi
    else
        echo "pick server by alias: $1"
       servconf=$(pickbyname $1)
        if [ -n "$servconf" ];then
            readparam $servconf
        fi
    fi

    if [ -n "$servconf" -a -n "$name" ];then
        echo "Link Server: $name .."
        sshcmd $encoding $name $passwd $server $port
    else
        echo "No Match Server Found"
    fi
}

# main use of function
function dsftp {
    if [ $# -lt 1 ];then
        #list all
        listservers
        return
    fi

    if [ "x$1" = "x-f" ];then
        listservers -full
        return
    fi

    isid=$(expr "$1" : "^[0-9]")
    if [ $isid -eq 1 ];then
        # by Id
        echo "pick server by id: $1"
        servconf=$(pickbyid $1)
        if [ -n "$servconf" ];then
            readparam $servconf
        fi
    else
        echo "pick server by alias: $1"
       servconf=$(pickbyname $1)
        if [ -n "$servconf" ];then
            readparam $servconf
        fi
    fi

    if [ -n "$name" ];then
        echo "Link Server: $name .."
        sftpcmd $name $passwd $server $port
    else
        echo "No Match Server Found"
    fi
}

# main maintain function
function lssh {
    if [ $# -lt 2 ];then
        echo "usage: $0 <action> <Id> [newId] ..."
        echo "  action:"
        echo "          init"
        echo "          add"
        echo "          upd"
        echo "          del"
        echo "# id  alias-name  server:port  encoding    passwd"
        return 1
    fi

    act=$1
    shift
    case "$act" in
        'init')
            initdb
            ;;
        'add')
            addserver $1 $2 $3 $4 $5
            ;;
        'upd')
            upserver $1 $2 $3 $4 $5 $6
            ;;
        'del')
            delserver $1
            ;;
        *)
            echo "invald action"
            ;;
    esac
}
