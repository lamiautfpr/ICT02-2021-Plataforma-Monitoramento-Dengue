#!/bin/bash

# Inicia o SSH
/etc/init.d/ssh start

# Formata o namenode do HDFS
$HADOOP_HOME/bin/hdfs namenode -format -nonInteractive

# Inicia todos os servicos do Hadoop
$HADOOP_HOME/sbin/start-all.sh
# Inicia os serviços do master do Spark
$SPARK_HOME/sbin/start-master.sh

# Cria pasta do flume
mkdir -p /app/data/flume

# Inicia o Flume com as configurações definidas no arquivo configs/flume/flume.conf desse projeto
$FLUME_HOME/bin/flume-ng agent --conf conf --conf-file $FLUME_HOME/flume.conf --name a1 -Dflume.root.looger=INFO,console &

# Mantem o conteiner ativo após a inicialização
tail -f /dev/null