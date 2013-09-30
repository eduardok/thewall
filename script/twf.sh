#!/bin/bash
#-----------------------------------------------------------------------------+
# twf                                                                         |
# The Wall Firewall System                                                    |
#-----------------------------------------------------------------------------+
# Arquivo de Montagem do Firewall                                             |
#-----------------------------------------------------------------------------+

#
# PATH do TWF                            
#

TWF_DIR=/etc/TheWall

#
# Variavel Global
#

TWF_ERROR="00"

#
# Arquivo de Configuracao
#

if [ -x ${TWF_DIR}/conf/twf.conf ]; then
   . ${TWF_DIR}/conf/twf.conf
   echo "TWF: The Wall Firewall Script v${TWF_INFO_VERSION}"
   echo "TWF: Ativando Script para ${TWF_INFO_HOST}"
else
   TWF_ERROR="01"
fi

#
# Verificacao oa LIB de regras
#

if [ ! -d ${TWF_DIR}/lib ]; then
   TWF_ERROR="02"
else
   if [ ! -d ${TWF_DIR}/lib/forward ]; then
      TWF_ERROR="03"
   else
      if [ ! -d ${TWF_DIR}/lib/nat ]; then
         TWF_ERROR="04"
      fi
   fi
fi

#
# Tratamento de Erros
#

if [ "${TWF_ERROR}" == "01" ]; then
   echo " "
   echo "TWF: ERRO FATAL 01 - twf.conf nao existe ou nao pode ser executado!!!"
   echo " "
   exit
fi

if [ "${TWF_ERROR}" == "02" ]; then
   echo " "
   echo "TWF: ERRO FATAL 02 - pasta dos arquivos de configuracao nao existe!!!"
   echo " "
   exit
fi

if [ "${TWF_ERROR}" == "03" ]; then
   echo " "
   echo "TWF: ERRO FATAL 03 - pasta das regras de roetamento nao existe!!!"
   echo " "
   exit
fi

if [ "${TWF_ERROR}" == "04" ]; then
   echo " "
   echo "TWF: ERRO FATAL 04 - pasta das regras de NAT nao existe!!!"
   echo " "
   exit
fi

# Se a opcao for "" 
if [ "${1}" == "" ]; then
   echo "TheWall: sintaxe ${TWF_DIR}/bin/twf {start|stop|reload|status|panic}"
   exit
fi

# Se a opcao for panic
if [ "${1}" == "panic" ]; then
   ${TWF_IPT} -F -t filter
   ${TWF_IPT} -F -t nat
   ${TWF_IPT} -F -t mangle
   ${TWF_IPT} -X -t filter
   ${TWF_IPT} -X -t nat   
   ${TWF_IPT} -X -t mangle

   ${TWF_IPT} -t filter -P INPUT       DROP
   ${TWF_IPT} -t filter -P OUTPUT      DROP
   ${TWF_IPT} -t filter -P FORWARD     DROP

   ${TWF_IPT} -t nat    -P PREROUTING  DROP
   ${TWF_IPT} -t nat    -P OUTPUT      DROP
   ${TWF_IPT} -t nat    -P POSTROUTING DROP

   ${TWF_IPT} -t mangle -P PREROUTING  DROP
   ${TWF_IPT} -t mangle -P OUTPUT      DROP
   exit
fi

# Se a opcao for status
if [ "${1}" == "status" ]; then
   echo "" > ${TWF_DIR}/log/status.log
   echo "TheWall" >> ${TWF_DIR}/log/status.log
   echo "Status do Sistema" >> ${TWF_DIR}/log/status.log
   echo "-----------------" >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   echo "Tabela FILTER" >> ${TWF_DIR}/log/status.log
   echo "-----------------" >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   ${TWF_IPT} -v -L -n -t filter  >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   echo "Tabela NAT" >> ${TWF_DIR}/log/status.log
   echo "-----------------" >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   ${TWF_IPT} -v -L -n -t nat >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   echo "Tabela MANGLE" >> ${TWF_DIR}/log/status.log
   echo "-----------------" >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   ${TWF_IPT} -v -L -n -t mangle >> ${TWF_DIR}/log/status.log
   echo "" >> ${TWF_DIR}/log/status.log
   cat ${TWF_DIR}/log/status.log | less
   exit
fi

# Se a opcao for status
if [ "${1}" == "reload" ]; then
   ${TWF_DIR}/bin/twf stop
   ${TWF_DIR}/bin/twf start
   exit
fi

#
# Se auditar o LOG faca
#

if [ -f ${TWF_SYSLOG} ]; then
   echo "TWF: Verificando sistema de Auditoria do Sistema ..."
   if [ "${TWF_LOG}" != "NONE" ]; then
      SYSLOG=`grep "TWF" /etc/syslog.conf`
      if [ "${SYSLOG}" == "" ]; then
         echo "TWF: Configurando o Sistema de Auditoria do Sistema para ${TWF_DIR}/log ..."
         echo " " >> ${TWF_SYSLOG}
         echo "### TWF: Configuracap de auditoria do Sistema" >> ${TWF_SYSLOG}
         echo "kern.*						/var/log/messages" >> ${TWF_SYSLOG} 
      fi 
   fi
fi

#
# Limpando as Rergras carregadas com o Kernel
#

echo "TWF: Limpando as Tabelas de Filtragem e Tratamento de Pacotes ..."

${TWF_IPT} -F -t filter
${TWF_IPT} -F -t nat
${TWF_IPT} -F -t mangle
${TWF_IPT} -X -t filter
${TWF_IPT} -X -t nat   
${TWF_IPT} -X -t mangle

${TWF_IPT} -t filter -P INPUT       ACCEPT
${TWF_IPT} -t filter -P OUTPUT      ACCEPT
${TWF_IPT} -t filter -P FORWARD     ACCEPT

${TWF_IPT} -t nat    -P PREROUTING  ACCEPT
${TWF_IPT} -t nat    -P OUTPUT      ACCEPT
${TWF_IPT} -t nat    -P POSTROUTING ACCEPT

${TWF_IPT} -t mangle -P PREROUTING  ACCEPT
${TWF_IPT} -t mangle -P OUTPUT      ACCEPT

# Se a opcao for STOP
if [ "${1}" == "stop" ]; then
   echo "TWF: Script descarregado da memoria."
   echo ""
   exit
fi

#
# Protecao contra IP_SPOOFING 
#

if [ "${TWF_IP_SPOOFING}" == "Y" ]; then
   echo "TWF: Ativando protecao contra IP SPOOFING ..."
   for i in /proc/sys/net/ipv4/conf/*/rp_filter; do
      echo "1" >${i}
   done
else
   echo "TWF: Desativando protecao contra IP SPOOFING ..."
   for i in /proc/sys/net/ipv4/conf/*/rp_filter; do
      echo "0" >${i}
   done
fi

#
# O iptables define automaticamente o número máximo de conexões simultâneas 
# com base na memória do sistema. Para 32MB = 2048, 64MB = 4096, 128MB = 8192, 
# sendo que são usados 350 bytes de memória residente para controlar 
# cada conexão. 
# Quando este limite é excedido a seguinte mensagem é mostrada:
#  "ip_conntrack: maximum limit of XXX entries exceed"
#
# Como temos uma rede simples, vamos abaixar este limite. Por outro lado isto 
# criará uma certa limitação de tráfego para evitar a sobrecarga do servidor. 
#
echo "TWF: Configurando o numero maximo de conexoes simultaneas para ${TWF_CONNTRACK_MAX}..."
echo "${TWF_CONNTRACK_MAX}" > /proc/sys/net/ipv4/ip_conntrack_max
					      
#
# Ativando o Roteamento de Pacotes
#
if [ "${TWF_IP_FORWARD}" = "Y" ]; then
   echo "TWF: Ativando o Reenvio de Pacotes ..."
   echo "1" > /proc/sys/net/ipv4/ip_forward
else
   echo "TWF: Desativando o Reenvio de Pacotes ..."
   echo "0" > /proc/sys/net/ipv4/ip_forward
fi

#
# Definindo as Politicas padrao
#

echo "TWF: Configurando as politicas padrao de policiamento do TWF ..."
# Tabela filter
${TWF_IPT} -t filter -P INPUT       DROP
${TWF_IPT} -t filter -P OUTPUT      ACCEPT
${TWF_IPT} -t filter -P FORWARD     DROP

#
# Processando as Regras do Bastion Host
#
echo "TWF: Carregando configuracoes do Bastion Host ..."

# Aceitando todo o trafego da interface de Loopback
${TWF_IPT} -A INPUT  -i lo -j ACCEPT

# Regras do Bastion Host
REGRAS_BASTION=`ls ${TWF_DIR}/lib/bastion/twf*|wc|cut -c 1-7`

if [ "${REGRAS_BASTION}" -gt "0" ]; then
   # Processamento dos Arquivos de Regras	       
   for i in ${TWF_DIR}/lib/bastion/twf*; do
      # Excluindo o Template
      TEMPLATE=`echo ${i} | egrep template`
      if [ "${TEMPLATE}" != "" ]; then
	 continue
      fi

      # Reset das Informacoes
      TWF_NET_IN=
      TWF_NET_OUT=
      TWF_TCP_IN=
      TWF_TCP_OUT=
      TWF_UDP_IN=
      TWF_UDP_OUT=
      TWF_ICMP_IN=
      TWF_ICMP_OUT=
      TWF_DEV_IN=
      TWF_DEV_OUT=
      TWF_DEF_POL="ACCEPT"
      
      # Anexando as Configuracoes da Regra
      . ${i}
      
      # Validando as Informacoes
      if [ "${TWF_NET_IN}" == "" ]; then
	 echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_NET_OUT}" == "" ]; then
	 echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_DEV_IN}" == "" ]; then
	 echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_DEV_OUT}" == "" ]; then
	 echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	 continue
      fi

      # Formulando a Linha de Comando do IPTABLES
      echo "TWF:    [Bastion] Carregando ${i} ..."

      #Validacao dos Parametros
      if [ "${TWF_TCP_IN}" != "" ]; then
         echo "${TWF_TCP_IN}" | grep ":" >/dev/null
         if [ "$?" -eq 0 ]; then 
            TWF_TCP_IN="--sport ${TWF_TCP_IN}"
         else
            TWF_TCP_IN="-m multiport --sport ${TWF_TCP_IN}"
         fi
      fi
      if [ "${TWF_TCP_OUT}" != "" ]; then
         echo "${TWF_TCP_OUT}" | grep ":" >/dev/null
         if [ "$?" -eq 0 ]; then
            TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
         else
            TWF_TCP_OUT="-m multiport --dport ${TWF_TCP_OUT}"
         fi
      fi
      if [ "${TWF_UDP_IN}" != "" ]; then
         echo "${TWF_UDP_IN}" | grep ":" >/dev/null
         if [ "$?" -eq 0 ]; then
            TWF_UDP_IN="--sport ${TWF_UDP_IN}"
         else
            TWF_UDP_IN="-m multiport --sport ${TWF_UDP_IN}"
         fi
      fi
      if [ "${TWF_UDP_OUT}" != "" ]; then
         echo "${TWF_UDP_OUT}" | grep ":" >/dev/null
         if [ "$?" -eq 0 ]; then
            TWF_UDP_OUT="--dport ${TWF_UDP_OUT}"
         else
  	    TWF_UDP_OUT="-m multiport --dport ${TWF_UDP_OUT}"
  	 fi
      fi

      # Linhas de Comando
      TWF_COMMAND_TCP_01="${TWF_IPT} -A INPUT -p tcp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT}  -d ${TWF_NET_IN} "${TWF_TCP_IN}"   -j ${TWF_DEF_POL}"
      TWF_COMMAND_TCP_02="${TWF_IPT} -A INPUT -p tcp -i ${TWF_DEV_OUT} -s ${TWF_NET_IN} ${TWF_TCP_IN}  -d ${TWF_NET_OUT} "${TWF_TCP_OUT}" -j ${TWF_DEF_POL}"
      
      TWF_COMMAND_UDP_01="${TWF_IPT} -A INPUT -p udp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT}  -d ${TWF_NET_IN} "${TWF_UDP_IN}"   -j ${TWF_DEF_POL}"
      TWF_COMMAND_UDP_02="${TWF_IPT} -A INPUT -p udp -i ${TWF_DEV_OUT} -s ${TWF_NET_IN} ${TWF_UDP_IN}  -d ${TWF_NET_OUT} "${TWF_UDP_OUT}" -j ${TWF_DEF_POL}"

      TWF_COMMAND_ICM_01="${TWF_IPT} -A INPUT -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT} -d ${TWF_NET_IN} --icmp-type echo-request  -j ACCEPT"
      TWF_COMMAND_ICM_02="${TWF_IPT} -A INPUT -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT} -d ${TWF_NET_IN} --icmp-type echo-reply    -j ACCEPT"
      
      TWF_COMMAND_ICM_03="${TWF_IPT} -A INPUT -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_IN}  -d ${TWF_NET_OUT} --icmp-type echo-request -j ACCEPT"
      TWF_COMMAND_ICM_04="${TWF_IPT} -A INPUT -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_IN}  -d ${TWF_NET_OUT} --icmp-type echo-reply   -j ACCEPT"

      # Acionando as Regras

      #DENY=`echo ${TWF_TCP_IN}|egrep -i none`
      #if [ "${DENY}" == "" ]; then
      #   eval "${TWF_COMMAND_TCP_01} >> ${TWF_DIR}/log/error.log 2>&1"
      #fi
      DENY=`echo ${TWF_TCP_OUT}|egrep -i none`
      if [ "${DENY}" == "" ]; then
         eval "${TWF_COMMAND_TCP_02} >> ${TWF_DIR}/log/error.log 2>&1"
      fi
      #DENY=`echo ${TWF_UDP_IN}|egrep -i none`
      #if [ "${DENY}" == "" ]; then
      #   eval "${TWF_COMMAND_UDP_01} >> ${TWF_DIR}/log/error.log 2>&1"
      #fi
      DENY=`echo ${TWF_UDP_OUT}|egrep -i none`
      if [ "${DENY}" == "" ]; then
         eval "${TWF_COMMAND_UDP_02} >> ${TWF_DIR}/log/error.log 2>&1"
      fi
      
      # Avaliando a Opcao de DROP_ICMP
      if [ "${TWF_DROP_ICMP}" != "Y" ]; then
	 if [ "${TWF_DROP_ICMP_IN}" == "N" ]; then 
            eval "${TWF_COMMAND_ICM_01} >> ${TWF_DIR}/log/error.log 2>&1"
            eval "${TWF_COMMAND_ICM_02} >> ${TWF_DIR}/log/error.log 2>&1"
	 fi
	 if [ "${TWF_DROP_ICMP_OUT}" == "N" ]; then
            eval "${TWF_COMMAND_ICM_03} >> ${TWF_DIR}/log/error.log 2>&1"
            eval "${TWF_COMMAND_ICM_04} >> ${TWF_DIR}/log/error.log 2>&1"
	 fi
      fi

   done
   # Rejeitar qualquer conexao que tenha alguma ja iniciada ou relacionada
   ${TWF_IPT} -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
   
fi

# LOG
if [ "${TWF_LOG}" == "Y" ]; then
   ${TWF_IPT} -A INPUT -m state --state ! ESTABLISHED,RELATED -j LOG --log-prefix="[Bastion]: " 
fi

# Filtros de Trojan Horses
if [ "${TWF_DROP_TROJAN}" == "Y" ]; then
   if [ ! -f ${TWF_DIR}/lib/trojanlist ]; then
      echo "TWF:    [Bastion] Erro!!! Arquivo de Trojan nao existe ..."
   else
      REGRAS_TROJAN=`ls ${TWF_DIR}/lib/bastion/trj*|wc|cut -c 1-7`
      if [ "${REGRAS_TROJAN}" -gt "0" ]; then
	 BANNER="N"
         for i in ${TWF_DIR}/lib/bastion/trj*; do
            # Excluindo o Template
            TEMPLATE=`echo ${i} | egrep template`
            if [ "${TEMPLATE}" != "" ]; then
	       BANNER="Y"
      	       continue
            fi
	    if [ "${BANNER}" == "Y" ]; then
	       BANNER="N"
               echo "TWF:    [Bastion] Carregando Filtros para Trojan Horses ..."
	    fi

            # Reset das Informacoes
            IP=
            IF=

	    . ${i}

	    if [ "${IP}" == "" ]; then
	       echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	       continue
	    fi
	    if [ "${IF}" == "" ]; then
	       echo "TWF:    [Bastion] Erro na Configuracao do Bastion (${i})!!! Ignorado ..."
	       continue
	    fi

	    if [ "${IP}" != "" ]; then
	       IP="-d ${IP}"
	    fi

	    if [ "${IF}" != "" ]; then
	       IF="-i ${IF}"
	    fi
	       
            cat ${TWF_DIR}/lib/trojanlist | cut -d ":" -f 1 | \
            while read port; do
               ${TWF_IPT} -A INPUT -p tcp ${IP} ${IF} --dport ${port} -j REJECT
               ${TWF_IPT} -A INPUT -p udp ${IP} ${IF} --dport ${port} -j REJECT
   	       if [ "${TWF_LOG}" == "Y" ]; then
                  ${TWF_IPT} -A INPUT -p tcp ${IP} ${IF} --dport ${port} -j LOG --log-prefix="[Trojan]: "
                  ${TWF_IPT} -A INPUT -p udp ${IP} ${IF} --dport ${port} -j LOG --log-prefix="[Trojan]: "
 	       fi
            done
	    
	 done
      fi
   fi
fi

# Ajustando o REJECT padrao
if [ "${TWF_RULE_BASTION}" == "REJECT" ]; then 
   ${TWF_IPT} -A INPUT -j REJECT
else
   ${TWF_IPT} -A INPUT -j DROP
fi

#
# Regras para o Roteamento de Pacotes
#
if [ "${TWF_IP_FORWARD}" = "N" ]; then
   echo "TWF: Desativando configuracoes do roteamento de pacotes.."
   # Ajustando o REJECT padrao
   if [ "${TWF_RULE_ROUTING}" == "REJECT" ]; then 
      ${TWF_IPT} -A FORWARD -j REJECT
   else
      ${TWF_IPT} -A FORWARD -j DROP
   fi
   echo "TWF: Script carregado na memoria."
   exit
fi

echo "TWF: Carregando configuracoes do roteamento de pacotes.."

# Regras do Forward
REGRAS_FORWARD=`ls ${TWF_DIR}/lib/forward/twf*|wc|cut -c 1-7`

if [ "${REGRAS_FORWARD}" -gt "0" ]; then
   # Processamento dos Arquivos de Regras
   for i in ${TWF_DIR}/lib/forward/twf*; do
      # Excluindo o Template
      TEMPLATE=`echo ${i} | egrep template`
      if [ "${TEMPLATE}" != "" ]; then
	 continue
      fi

      # Reset das Informacoes
      TWF_NET_IN=
      TWF_NET_OUT=
      TWF_TCP_IN=
      TWF_TCP_OUT=
      TWF_UDP_IN=
      TWF_UDP_OUT=
      TWF_ICMP_IN=
      TWF_ICMP_OUT=
      TWF_DEV_IN=
      TWF_DEV_OUT=
      TWF_DEF_POL="ACCEPT"
      
      # Anexando as Configuracoes da Regra
      . ${i}
      
      # Validando as Informacoes
      if [ "${TWF_NET_IN}" == "" ]; then
	 echo "TWF:    [Forward] Erro na Configuracao do Roteamento (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_NET_OUT}" == "" ]; then
	 echo "TWF:    [Forward] Erro na Configuracao do Roteamento (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_DEV_IN}" == "" ]; then
	 echo "TWF:    [Forward] Erro na Configuracao do Roteamento (${i})!!! Ignorado ..."
	 continue
      fi
      if [ "${TWF_DEV_OUT}" == "" ]; then
	 echo "TWF:    [Forward] Erro na Configuracao do Roteamento (${i})!!! Ignorado ..."
	 continue
      fi

      # Formulando a Linha de Comando do IPTABLES
      echo "TWF:    [Forward] Carregando ${i} ..."

      #Validacao dos Parametros
      if [ "${TWF_TCP_IN}" != "" ]; then
         TWF_TCP_IN="-m multiport --sport ${TWF_TCP_IN}"
      fi
      if [ "${TWF_TCP_OUT}" != "" ]; then
         echo "${TWF_TCP_OUT}" | grep '!' >/dev/null
         if [ "$?" -eq 0 ]; then
     	    TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
     	 else
     	    TWF_TCP_OUT="-m multiport --dport ${TWF_TCP_OUT}"
     	 fi
      fi
      if [ "${TWF_UDP_IN}" != "" ]; then
         TWF_UDP_IN="-m multiport --sport ${TWF_UDP_IN}"
      fi
      if [ "${TWF_UDP_OUT}" != "" ]; then
	 TWF_UDP_OUT="-m multiport --dport ${TWF_UDP_OUT}"
      fi

      # Linhas de Comando
      TWF_COMMAND_TCP_01="${TWF_IPT} -A FORWARD -p tcp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT}  -o ${TWF_DEV_IN}  -d ${TWF_NET_IN} ${TWF_TCP_IN}   -j ${TWF_DEF_POL}"
      TWF_COMMAND_TCP_02="${TWF_IPT} -A FORWARD -p tcp -i ${TWF_DEV_IN}  -s ${TWF_NET_IN} ${TWF_TCP_IN}  -o ${TWF_DEV_OUT} -d ${TWF_NET_OUT} ${TWF_TCP_OUT} -j ${TWF_DEF_POL}"
#      echo $TWF_COMMAND_TCP_01
#      echo $TWF_COMMAND_TCP_02
      TWF_COMMAND_UDP_01="${TWF_IPT} -A FORWARD -p udp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT}  -o ${TWF_DEV_IN}  -d ${TWF_NET_IN} ${TWF_UDP_IN}   -j ${TWF_DEF_POL}"
      TWF_COMMAND_UDP_02="${TWF_IPT} -A FORWARD -p udp -i ${TWF_DEV_IN}  -s ${TWF_NET_IN} ${TWF_UDP_IN}  -o ${TWF_DEV_OUT} -d ${TWF_NET_OUT} ${TWF_UDP_OUT} -j ${TWF_DEF_POL}"
      
      TWF_COMMAND_ICM_01="${TWF_IPT} -A FORWARD -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT} -o ${TWF_DEV_IN}  -d ${TWF_NET_IN} --icmp-type echo-request  -j ACCEPT"
      TWF_COMMAND_ICM_02="${TWF_IPT} -A FORWARD -p icmp -i ${TWF_DEV_OUT} -s ${TWF_NET_OUT} -o ${TWF_DEV_IN}  -d ${TWF_NET_IN} --icmp-type echo-reply    -j ACCEPT"
      
      TWF_COMMAND_ICM_03="${TWF_IPT} -A FORWARD -p icmp -i ${TWF_DEV_IN}  -s ${TWF_NET_IN}  -o ${TWF_DEV_OUT} -d ${TWF_NET_OUT} --icmp-type echo-request -j ACCEPT"
      TWF_COMMAND_ICM_04="${TWF_IPT} -A FORWARD -p icmp -i ${TWF_DEV_IN}  -s ${TWF_NET_IN}  -o ${TWF_DEV_OUT} -d ${TWF_NET_OUT} --icmp-type echo-reply   -j ACCEPT"

      # Acionando as Regras
      #DENY=`echo ${TWF_TCP_IN}|egrep -i none`
      #if [ "${DENY}" == "" ]; then
      #	 echo ""
      #   #eval "${TWF_COMMAND_TCP_01} >> ${TWF_DIR}/log/error.log 2>&1"
      #fi
      DENY=`echo ${TWF_TCP_OUT}|egrep -i none`
      if [ "${DENY}" == "" ]; then
         eval "${TWF_COMMAND_TCP_02} >> ${TWF_DIR}/log/error.log 2>&1"
      fi
      #DENY=`echo ${TWF_UDP_IN}|egrep -i none`
      #if [ "${DENY}" == "" ]; then
      #	 echo ""
      #   #eval "${TWF_COMMAND_UDP_01} >> ${TWF_DIR}/log/error.log 2>&1"
      #fi
      DENY=`echo ${TWF_UDP_OUT}|egrep -i none`
      if [ "${DENY}" == "" ]; then
         eval "${TWF_COMMAND_UDP_02} >> ${TWF_DIR}/log/error.log 2>&1"
      fi
      
      # Avaliando a Opcao de DROP_ICMP
      if [ "${TWF_DROP_ICMP}" != "Y" ]; then
	 if [ "${TWF_DROP_ICMP_IN}" == "N" ]; then 
            eval "${TWF_COMMAND_ICM_01} >> ${TWF_DIR}/log/error.log 2>&1"
            eval "${TWF_COMMAND_ICM_02} >> ${TWF_DIR}/log/error.log 2>&1"
	 fi
	 if [ "${TWF_DROP_ICMP_OUT}" == "N" ]; then
            eval "${TWF_COMMAND_ICM_03} >> ${TWF_DIR}/log/error.log 2>&1"
            eval "${TWF_COMMAND_ICM_04} >> ${TWF_DIR}/log/error.log 2>&1"
	 fi
      fi

   done
  
   # Aceitar qualquer conexao que tenha alguma ja iniciada ou relacionada
   ${TWF_IPT} -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
   
fi

# LOG
if [ "${TWF_LOG}" == "Y" ]; then
   ${TWF_IPT} -A FORWARD -m state --state ! ESTABLISHED,RELATED -j LOG --log-prefix="[Forward]: " 
fi

# Filtros de Trojan Horses
if [ "${TWF_DROP_TROJAN}" == "Y" ]; then
   if [ ! -f ${TWF_DIR}/lib/trojanlist ]; then
      echo "TWF:    [Forward] Erro!!! Arquivo de Trojan nao existe ..."
   else
      REGRAS_TROJAN=`ls ${TWF_DIR}/lib/forward/trj*|wc|cut -c 1-7`
      if [ "${REGRAS_TROJAN}" -gt "0" ]; then
	 BANNER="N"
         for i in ${TWF_DIR}/lib/forward/trj*; do
            # Excluindo o Template
            TEMPLATE=`echo ${i} | egrep template`
            if [ "${TEMPLATE}" != "" ]; then
	       BANNER="Y"
      	       continue
            fi
	    if [ "${BANNER}" == "Y" ]; then
	       BANNER="N"
               echo "TWF:    [Forward] Carregando Filtros para Trojan Horses ..."
	    fi
            # Reset das Informacoes
            IP=
            IF=

	    . ${i}

	    if [ "${IP}" == "" ]; then
	       echo "TWF:    [Forward] Erro na Configuracao do Filtro (${i})!!! Ignorado ..."
	       continue
	    fi
	    if [ "${IF}" == "" ]; then
	       echo "TWF:    [Forward] Erro na Configuracao do Filtro (${i})!!! Ignorado ..."
	       continue
	    fi

	    if [ "${IP}" != "" ]; then
	       IP="-d ${IP}"
	    fi

	    if [ "${IF}" != "" ]; then
	       IF="-i ${IF}"
	    fi
	       
            cat ${TWF_DIR}/lib/trojanlist | cut -d ":" -f 1 | \
            while read port; do
               ${TWF_IPT} -A FORWARD -p tcp ${IP} ${IF} --dport ${port} -j REJECT
               ${TWF_IPT} -A FORWARD -p udp ${IP} ${IF} --dport ${port} -j REJECT
   	       if [ "${TWF_LOG}" == "Y" ]; then
                  ${TWF_IPT} -A FORWARD -p tcp ${IP} ${IF} --dport ${port} -j LOG --log-prefix="TWF [Trojan]: "
                  ${TWF_IPT} -A FORWARD -p udp ${IP} ${IF} --dport ${port} -j LOG --log-prefix="TWF [Trojan]: "
 	       fi
            done
	    
	 done
      fi
   fi
fi

# Ajustando o REJECT padrao
if [ "${TWF_RULE_BASTION}" == "REJECT" ]; then 
   ${TWF_IPT} -A FORWARD -j REJECT
else
   ${TWF_IPT} -A FORWARD -j DROP
fi

#
# Regras da Tabela de NAT
#

echo "TWF: Carregando configuracoes da Tabela de Endereços (NAT).."

# Regras do Forward
REGRAS_NAT=`ls ${TWF_DIR}/lib/nat/twf*|wc|cut -c 1-7`

if [ "${REGRAS_NAT}" -gt "0" ]; then
   for i in ${TWF_DIR}/lib/nat/twf*; do
      # Excluindo o Template
      TEMPLATE=`echo ${i} | egrep template`
      if [ "${TEMPLATE}" != "" ]; then
	 continue
      fi

      # Reset das Informacoes
      TWF_NAT=   
      TWF_DEV=
      TWF_NET_NAT=
      TWF_NET_IN=
      TWF_NET_OUT=
      TWF_TCP_IN=
      TWF_TCP_OUT=
      TWF_UDP_IN=
      TWF_UDP_OUT=
      
      # Anexando as Configuracoes da Regra
      . ${i}
      
      # Validando as Informacoes
      if [ "${TWF_NAT}" == "" ]; then
	 echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ...1"
	 continue
      fi
      if [ "${TWF_DEV}" == "" ]; then
	 echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ...2"
	 continue
      fi
      
      # Formulando a Linha de Comando do IPTABLES
      echo "TWF:    [NAT] Carregando ${i} ..."
      
      # Decidindo o Tipo de NAT
      if [ "${TWF_NAT}" == "M" ]; then
	 # Verificacao da Origem
	 if [ "${TWF_NET_IN}" == "" ]; then
	    echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ...3"
	    continue
	 fi
	 # Se foram especificadas portas TCP ou UDP de origem
	 if [ "${TWF_TCP_IN}" != "" ]; then
	    TWF_TCP_IN="--sport ${TWF_TCP_IN}"
	 fi
	 if [ "${TWF_UDP_OUT}" != "" ]; then
	    TWF_UDP_IN="--sport ${TWF_UDP_IN}"
	 fi
	 # Se for especificado um destino para a regra
	 if [ "${TWF_NET_OUT}" != "" ]; then
	    TWF_NET_OUT="-d ${TWF_NET_OUT}"
	    if [ "${TWF_TCP_OUT}" != "" ]; then
	       TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
	    fi
	    if [ "${TWF_UDP_OUT}" != "" ]; then
	       TWF_UDP_OUT="--dport ${TWF_UDP_OUT}"
	    fi
	 else
	    TWF_TCP_OUT=
	    TWF_UDP_OUT=
	 fi
	 # Linha de Comando
	 NAT_TCP="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p tcp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j MASQUERADE"
	 NAT_UDP="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p udp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j MASQUERADE"
	 NAT_ICM="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p icmp -s ${TWF_NET_IN} ${TWF_NET_OUT} -j MASQUERADE"
	 NAT_ALL="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -s ${TWF_NET_IN} ${TWF_NET_OUT} -j MASQUERADE"
      else 
	 if [ "${TWF_NAT}" == "S" ]; then
	    # Verificacao da Origem
	    if [ "${TWF_NET_IN}" == "" ]; then
	       echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ..."
	       continue
	    fi
	    # Se foram especificadas portas TCP ou UDP de origem
	    if [ "${TWF_TCP_IN}" != "" ]; then
	       TWF_TCP_IN="--sport ${TWF_TCP_IN}"
	    fi
	    if [ "${TWF_UDP_OUT}" != "" ]; then
	       TWF_UDP_IN="--sport ${TWF_UDP_IN}"
	    fi
	    # Se for especificado um destino para a regra
	    if [ "${TWF_NET_OUT}" != "" ]; then
	       TWF_NET_OUT="-d ${TWF_NET_OUT}"
	       if [ "${TWF_TCP_OUT}" != "" ]; then
	          TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
	       fi
	       if [ "${TWF_UDP_OUT}" != "" ]; then
	          TWF_UDP_OUT="--dport ${TWF_UDP_OUT}"
	       fi
	    else
	       TWF_TCP_OUT=
	       TWF_UDP_OUT=
	    fi
	    # Obrigatoriedade do IP do NAT
	    if [ "${TWF_NET_NAT}" == "" ]; then
	       echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ..."
	       continue
            fi
	    # Linha de Comando
	    NAT_TCP="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p tcp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j SNAT --to ${TWF_NET_NAT}"
	    NAT_UDP="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p udp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j SNAT --to ${TWF_NET_NAT}"
	    NAT_ICM="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -p icmp -s ${TWF_NET_IN} ${TWF_NET_OUT} -j SNAT --to ${TWF_NET_NAT}"
	    NAT_ALL="${TWF_IPT} -t nat -A POSTROUTING -o ${TWF_DEV} -s ${TWF_NET_IN} ${TWF_NET_OUT} -j SNAT --to ${TWF_NET_NAT}"
         else 
            if [ "${TWF_NAT}" == "D" ]; then

	       # Verificacao da Origem
	       if [ "${TWF_NET_IN}" == "" ]; then
	          echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ..."
	          continue
	       fi
	       # Se foram especificadas portas TCP ou UDP de origem
	       if [ "${TWF_TCP_IN}" != "" ]; then
	          TWF_TCP_IN="--sport ${TWF_TCP_IN}"
	       fi
	       if [ "${TWF_UDP_OUT}" != "" ]; then
	          TWF_UDP_IN="--sport ${TWF_UDP_IN}"
	       fi
	       # Se for especificado um destino para a regra
	       if [ "${TWF_NET_OUT}" != "" ]; then
	          TWF_NET_OUT="-d ${TWF_NET_OUT}"
	          if [ "${TWF_TCP_OUT}" != "" ]; then
	             TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
	          fi
	          if [ "${TWF_UDP_OUT}" != "" ]; then
	             TWF_UDP_OUT="--dport ${TWF_UDP_OUT}"
	          fi
	       else
	          TWF_TCP_OUT=
	          TWF_UDP_OUT=
	       fi
	       # Obrigatoriedade do IP do NAT
	       if [ "${TWF_NET_NAT}" == "" ]; then
	          echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ..."
	          continue
               fi
	       # Linha de Comando
	       NAT_TCP="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p tcp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j DNAT --to ${TWF_NET_NAT}"
	       NAT_UDP="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p udp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j DNAT --to ${TWF_NET_NAT}"
	       NAT_ICM="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p icmp -s ${TWF_NET_IN} ${TWF_NET_OUT} -j DNAT --to ${TWF_NET_NAT}"
	       NAT_ALL="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -s ${TWF_NET_IN} ${TWF_NET_OUT} -j DNAT --to ${TWF_NET_NAT}"
	    elif [ "${TWF_NAT}" == "R" ]; then

	       # Verificacao da Origem
	       if [ "${TWF_NET_IN}" == "" ]; then
	          echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ...4"
	          continue
	       fi
	       # Se foram especificadas portas TCP ou UDP de origem
	       #if [ "${TWF_TCP_IN}" != "" ]; then
	       #   TWF_TCP_IN="--sport ${TWF_TCP_IN}"
	       #fi
	       #if [ "${TWF_UDP_OUT}" != "" ]; then
	       #   TWF_UDP_IN="--sport ${TWF_UDP_IN}"
	       #fi
	       # Se for especificado um destino para a regra
	       #if [ "${TWF_NET_OUT}" != "" ]; then
	       #   TWF_NET_OUT="-d ${TWF_NET_OUT}"
	       #   if [ "${TWF_TCP_OUT}" != "" ]; then
	       #      TWF_TCP_OUT="--dport ${TWF_TCP_OUT}"
	       #   fi
	       #   if [ "${TWF_UDP_OUT}" != "" ]; then
	       #      TWF_UDP_OUT="--dport ${TWF_UDP_OUT}"
	       #   fi
	       #else
	       #   TWF_TCP_OUT=
	       #   TWF_UDP_OUT=
	       #fi
	       # Obrigatoriedade do IP do NAT
	       #if [ "${TWF_NET_NAT}" == "" ]; then
	       #   echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ...5"	
	       #   continue
               #fi
	       # Linha de Comando
	       #iptables -t nat -A PREROUTING -s 192.168.11.0/24 -p tcp --dport 80 -j REDIRECT --to-port 3128
              #NAT_TCP="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p tcp  -s ${TWF_NET_IN} ${TWF_TCP_IN} ${TWF_NET_OUT} ${TWF_TCP_OUT} -j DNAT --to ${TWF_NET_NAT}"
	       ${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p tcp  -s ${TWF_NET_IN} --dport ${TWF_TCP_IN} -j REDIRECT --to-port ${TWF_TCP_OUT}
#	       NAT_UDP="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p udp  -s ${TWF_NET_IN} --dport ${TWF_UDP_IN} -j REDIRECT --to-port ${TWF_UDP_OUT}"
	       #NAT_ICM="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -p icmp -s ${TWF_NET_IN} ${TWF_NET_OUT} -j REDIRECT --to-port ${TWF_NET_NAT}"
	       #NAT_ALL="${TWF_IPT} -t nat -A PREROUTING -i ${TWF_DEV} -s ${TWF_NET_IN} ${TWF_NET_OUT} -j REDIRECT --to-port ${TWF_NET_NAT}"
	       echo $NAT_TCP
#	       echo $NAT_UDP
            else
   	       echo "TWF:    [NAT] Erro na Configuracao do NAT (${i})!!! Ignorado ..."
   	       continue
            fi
	 fi
      fi

      NAT_PROTO="N"

      if [ "${TWF_TCP_IN}" != "" ]; then
	 NAT_PROTO="Y"
      else 
	 if [ "${TWF_TCP_OUT}" != "" ]; then
	    NAT_PROTO="Y"
         else 
            if [ "${TWF_UDP_IN}" != "" ]; then
	       NAT_PROTO="Y"
            else if [ "${TWF_UDP_OUT}" != "" ]; then
   	       NAT_PROTO="Y"
            fi
	 fi
      fi	 
     
      if [ "${NAT_PROTO}" == "Y" ]; then
	 eval "${NAT_TCP} >> ${TWF_DIR}/log/error.log 2>&1"
	 eval "${NAT_UDP} >> ${TWF_DIR}/log/error.log 2>&1"
      else
	 eval "${NAT_ALL} >> ${TWF_DIR}/log/error.log 2>&1"
      fi 
      
      # Avaliando a Opcao de DROP_ICMP
      if [ "${TWF_DROP_ICMP}" != "Y" ]; then
         if [ "${NAT_PROTO}" == "Y" ]; then
	    eval "${NAT_ICM} >> ${TWF_DIR}/log/error.log 2>&1"
	 fi
      fi;fi
   done
fi

# Definicoes de OUTPUT
#${TWF_IPT} -I FORWARD -j DROP -p tcp -m string --string ".info" -i eth0
# Definicao de Padroes de Espera em Mangle
echo "TWF: Configuracoes da Saida de Pacotes.."
#${TWF_IPT} -t mangle -A OUTPUT -p udp --dport 20 -j TOS --set-tos 0x8  >> ${TWF_DIR}/log/error.log 2>&1
#${TWF_IPT} -t mangle -A OUTPUT -p tcp --dport 21 -j TOS --set-tos 0x10 >> ${TWF_DIR}/log/error.log 2>&1
#${TWF_IPT} -t mangle -A OUTPUT -p udp --dport 53 -j TOS --set-tos 0x10 >> ${TWF_DIR}/log/error.log 2>&1

# Fim

echo "TWF: Script carregado na memoria."

#
# Final Script
#
