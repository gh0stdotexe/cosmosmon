#!/bin/sh
#
# Expose directory usage metrics, passed as an argument.
# Usage: add this to crontab:
#
# */5 * * * * prometheus directory-size.sh /var/lib/prometheus | sponge /var/lib/node_exporter/directory_size.prom
#
# sed pattern taken from https://www.robustperception.io/monitoring-directory-sizes-with-the-textfile-collector/
#
#
#ls -la $DATADIR/state/shared_memory.bin | awk ' { print $5 } '

get_memsize()
{
   echo "# HELP ${KRYPT}_total_ram ${KRNAME} Total RAM"
   echo "# TYPE ${KRYPT}_total_ram gauge"
   RAM=$(cat /proc/meminfo |grep MemTotal|awk '{print $2/1024/1024}'); echo "${KRYPT}_total_ram $RAM";
   echo "# HELP ${KRYPT}_size_of_db ${KRNAME} size of statedb database"
   echo "# TYPE ${KRYPT}_size_of_db gauge"
   DBSIZE=$(du -s ${DATADIR}/data | awk '{print $1}'); DBSIZE=$(echo "scale=2; $DBSIZE / 1048576" | bc); echo "${KRYPT}_size_of_db $DBSIZE";
   echo "# HELP ${KRYPT}_free_space_of_disk ${KRNAME} Free space of disk"
   echo "# TYPE ${KRYPT}_free_space_of_disk gauge"
   FREESPACEDISK=`df | grep $FSYS | awk '{print $4}'`; FREESPACEDISK=$(echo "scale=2; $FREESPACEDISK * 1024 / 1073741824" | bc); echo "${KRYPT}_free_space_of_disk $FREESPACEDISK"
} 

get_headblock()
{
   BLOCK=`curl --insecure --connect-timeout 6 --max-time 6  -s http://$IPADDR/abci_info | grep 'last_block_height' | awk -F ":" '{print $2}' | sed 's/"//g' | sed 's/,//g'`
   if [ -z $BLOCK ]; then
      echo "# HELP ${KRYPT}_head_block $KRNAME Head Block"
      echo "# TYPE ${KRYPT}_head_block gauge"
      echo "${KRYPT}_head_block -10"
   else
      echo "# HELP ${KRYPT}_head_block $KRNAME Head Block"
      echo "# TYPE ${KRYPT}_head_block gauge"
      echo "${KRYPT}_head_block $BLOCK"
   fi
}

get_cpu_usage()
{
   NODEPID=`netstat -tlpn 2>/dev/null | grep ":::26656"|awk '{print $4}'`
   if [ -z "$NODEPID" ]; then 
      echo ""
   else
      GAIADPID=$(ps aux | grep -v grep | grep 'gaiad' | awk '{print $2}' | sed 's/ //g');
      GAIADCPU=$(ps -p ${GAIADPID} -o %cpu | grep -v '%CPU'|sed 's/ //g');
   fi
   
   if [ -z $GAIADCPU ]; then
      echo "# HELP ${KRYPT}_cpu_usage $KRNAME Cpu Usage"
      echo "# TYPE ${KRYPT}_cpu_usage gauge"
      echo "${KRYPT}_cpu_usage -10"
   else
      echo "# HELP ${KRYPT}_cpu_usage $KRNAME Cpu Usage"
      echo "# TYPE ${KRYPT}_cpu_usage gauge"
      echo "${KRYPT}_cpu_usage $GAIADCPU"
   fi
}

get_mem_usage()
{
   NODEPID=`netstat -tlpn 2>/dev/null | grep ":::26656"|awk '{print $4}'`
   if [ -z "$NODEPID" ]; then
       echo ""
   else
      GAIADPID=$(ps aux | grep -v grep | grep 'gaiad' | awk '{print $2}' | sed 's/ //g')
      GAIADMEM=$(ps -p ${GAIADPID} -o %mem | grep -v '%MEM'|sed 's/ //g')
   fi

   if [ -z $GAIADMEM ]; then
      echo "# HELP ${KRYPT}_mem_usage $KRNAME Mem Usage"
      echo "# TYPE ${KRYPT}_mem_usage gauge"
      echo "${KRYPT}_mem_usage -10"
   else
      echo "# HELP ${KRYPT}_mem_usage $KRNAME Mem Usage"
      echo "# TYPE ${KRYPT}_mem_usage gauge"
      echo "${KRYPT}_mem_usage $GAIADMEM"
   fi
}

KRYPT="cosmos"
KRNAME="COSMOS"
DATADIR=/opt/cosmos
METRICDIR=/var/lib/node_exporter/textfile_collector
FSYS="/dev/md2"
IPADDR="1.1.1.1:26657"

while true; do
   echo "start"
   get_memsize > ${METRICDIR}/cosmos_metrics.prom
   get_headblock >> ${METRICDIR}/cosmos_metrics.prom
   get_cpu_usage >> ${METRICDIR}/cosmos_metrics.prom
   get_mem_usage >> ${METRICDIR}/cosmos_metrics.prom
   sleep 4;
done
