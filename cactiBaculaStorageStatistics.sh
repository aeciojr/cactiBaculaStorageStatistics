#!/bin/bash
 
##################################################################################### 
#                                                                                   #  
# Por       :  Aecio Junior <aeciojr@gmail.com>                                     #
# Data      :  Sáb Out 28 19:12:10 BRT 2017                                         #
#                                                                                   #
# Descricao :  Script p/ plotar grafico no cacti de staticas de ocupacao/capacidade #
#              de armazenamento (disco + fita) no bacula storage.                   #
#                                                                                   #
#####################################################################################
 
#-----------------------------------------------------------------------------------+
#                      >>> VARIAVEIS DE CONFIGURACAO  <<<                           |
#-----------------------------------------------------------------------------------+
 
## Host p/ conectar no banco de dados
DBHost=IPADDR
DBUserSO=username
DBSSHPort=7654

PGHost=host
PGUser=user
PGschema=schema
 
#-----------------------------------------------------------------------------------+
#                          >>> VARIAVEIS DO SCRIPT  <<<                             |
#-----------------------------------------------------------------------------------+
 
## Selects capacidade e ocupacao
SQLVolumesSize="select SUM(Media.VolBytes) as bytes_size from Media;"
SQLTotalBytes="select SUM(JobBytes) AS stored_bytes from Job where (endtime BETWEEN starttime AND endtime);"
 
#-----------------------------------------------------------------------------------+
#                               >>> FUNCOES  <<<                                    |
#-----------------------------------------------------------------------------------+
 
## Executa comandos remoto/SSH
_sshCommand(){
   local RC=0
   local Command="$@"
   ssh -p $DBSSHPort $DBHost -l $DBUserSO "$Command" || local RC=$?
   if [ $RC -ne 0 ]; then
      echo "Erro no SSH $DBHost $DBUserSO"
   fi
   return $RC
}
 
## Executa comandos no PG remoto
_psqlCommand(){
   local Command="$@"
   _sshCommand "psql --no-align -0 --tuples-only -U $PGUser -d $PGSchema -h $PGHost --command \"${Command}\" 2>/dev/null"
}
 
#-----------------------------------------------------------------------------------+
#                           >>> INICIO DO SCRIPT  <<<                               |
#-----------------------------------------------------------------------------------+
 
## Capacidade total de armazenamento (disco+fita)
VolumesSize=$( _psqlCommand "$SQLVolumesSize" )
 
## Total de bytes armazenados (todos os jobs) 
TotalBytes=$( _psqlCommand "$SQLTotalBytes" )
 
## Saldo de armazenamento disponivel (capacidade total - ocupacao)
DifferenceAvailable=$( expr $VolumesSize - $TotalBytes )
 
## Conversao de volumes (bytes >> giga)
TotalBytesGB=$( echo "$TotalBytes / 1024^3" | bc )
DifferenceAvailableGB=$( echo "$DifferenceAvailable / 1024^3" | bc )
 
## Saida (padrao cacti)
echo -n "volumessize:$DifferenceAvailableGB totalbytes:$TotalBytesGB"
 
#-----------------------------------------------------------------------------------+
#                             >>> FIM DO SCRIPT  <<<                                |
#-----------------------------------------------------------------------------------+
