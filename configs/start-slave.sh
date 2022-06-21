#!/bin/bash

# Inicia o SSH
/etc/init.d/ssh start

# Inicia o datanode do HDFS
$HADOOP_HOME/bin/hdfs --daemon start datanode
# Inicia o nodemanager do YARN
$HADOOP_HOME/bin/yarn --workers --daemon start nodemanager
# Por ter configurado o valor de hdfs://hadoop-master:9000 no arquivo core-site.xml, automaticamente é utilizado o container master como master

# Inicia os serviços do worker do Spark apontando para o master
$SPARK_HOME/sbin/start-worker.sh spark://hadoop-master:7077 

# Mantem o conteiner ativo após a inicialização
tail -f /dev/null