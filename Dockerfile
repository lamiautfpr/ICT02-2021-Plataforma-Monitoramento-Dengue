FROM ubuntu:20.04 AS slave

# Defini o diretório de uso
WORKDIR /app

# Configuração para informar o SO que o sistema não poderá interagir
# Necessário para evitar erros durante a instalação de pacotes que necessitam de input do usuário
ARG DEBIAN_FRONTEND=noninteractive
# Defini a fuso horário da máquina para evitar erro na instalação do pdsh 
ENV TZ=America/Sao_Paulo

# Definição da variável de ambiente do JAVA JDK
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

# Variáveis de ambiente utilizadas pelo HADOOP
ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/lib/native
ENV HADOOP_STREAMING $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar
# Definição de configurações que utilizam variáveis de ambiente são feitas aqui, já que não é possível utilizá-las nos arquivos de configurações
ENV HADOOP_OPTS "-Djava.library.path=$HADOOP_HOME/lib/native"

# Definir o usuário que roda-ra os serviços
ENV HDFS_NAMENODE_USER root
ENV HDFS_DATANODE_USER root
ENV HDFS_SECONDARYNAMENODE_USER root
ENV YARN_RESOURCEMANAGER_USER root
ENV YARN_NODEMANAGER_USER root

# Variáveis de ambiente utilizadas pelo YARN
ENV YARN_HOME $HADOOP_HOME

# Variáveis de ambiente utilizadas pelo SPARK
ENV SPARK_HOME /usr/local/spark
ENV PYSPARK_PYTHON /usr/bin/python3
# Define o charset utilizado pelo Python
ENV PYTHONIOENCODING utf8

# Faz o update e instala os pacotes SSH, PDSH e a JDK 8 do Java
RUN apt-get update && apt-get install -y ssh pdsh openjdk-8-jdk

# Cria a chave SSH e adiciona ela no authorized_keys
RUN \
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod 0600 ~/.ssh/authorized_keys 

# Copia os arquivos de instalação do Spark e Hadoop para a pasta de trabalho
COPY ["soft/spark-3.1.2-bin-hadoop3.2.tgz", "soft/hadoop-3.2.1.tar.gz", "./"]

# Descompacta e move os softwares para seus destinos definidos nas variáveis de ambiente
RUN tar -zxf hadoop-3.2.1.tar.gz && mv hadoop-3.2.1 $HADOOP_HOME
RUN tar xvf spark-3.1.2-bin-hadoop3.2.tgz && mv spark-3.1.2-bin-hadoop3.2 $SPARK_HOME

# Remove os arquivos desnecessários
RUN rm /app/*

# Correção do erro do PDSH
RUN sed -i 's/PDSH_SSH_ARGS_APPEND=/PDSH_RCMD_TYPE=ssh PDSH_SSH_ARGS_APPEND=/g' $HADOOP_HOME/libexec/hadoop-functions.sh

# Exporta as variáveis de ambiente e adiciona as pastas bin e sbin dos programas no PATH
RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
  echo "PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin" >> ~/.bashrc && \
  echo "export HADOOP_HOME=$HADOOP_HOME" >> $HIVE_HOME/bin/hive-config.sh

# Copia os arquivos de configurações do projeto para a pasta do Hadoop
ADD configs/hadoop/* $HADOOP_HOME/etc/hadoop/

# Copia os arquivo de inicialização do projeto para a container
ADD configs/start-slave.sh start-slave.sh

# Defini o comando de execução do Container que será rodado quando o container iniciar
CMD bash start-slave.sh

# Utiliza a imagem do Slave para fazer o Master
FROM slave AS master

# Variáveis de ambiente utilizadas pelo SQOOP
ENV SQOOP_HOME /usr/local/sqoop

# Variáveis de ambiente utilizadas pelo HIVE
ENV HIVE_HOME /usr/local/hive

# Variáveis de ambiente utilizadas pelo FLUME
ENV FLUME_HOME /usr/local/flume

# Copia os arquivos de instalação do Flume, Hive e Sqoop para a pasta de trabalho
COPY ["soft/apache*", "soft/Sqoop/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz", "./"]

# Descompacta e move os softwares para seus destinos definidos nas variáveis de ambiente
RUN tar xzf apache-hive-3.1.2-bin.tar.gz && mv apache-hive-3.1.2-bin $HIVE_HOME
RUN tar xzf apache-flume-1.9.0-bin.tar.gz && mv apache-flume-1.9.0-bin $FLUME_HOME
RUN tar xzf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz && mv sqoop-1.4.7.bin__hadoop-2.6.0 $SQOOP_HOME

# Remove os arquivos desnecessários
RUN rm /app/*

# Adiciona as pastas bin e sbin dos programas no PATH
RUN echo "PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$FLUME_HOME/bin:$HIVE_HOME/bin:$SQOOP_HOME/bin" >> ~/.bashrc

# Copia arquivo de configuração do projeto para a pasta do Sqoop, conf e .jars
ADD configs/sqoop/* $SQOOP_HOME/conf
ADD soft/Sqoop/jars/* $SQOOP_HOME/lib

# Remove .jar da lib do sqoop pra evitar conflito
RUN rm $SQOOP_HOME/lib/commons-lang3-3.4.jar 

# Copia os arquivos de configurações do projeto para a pasta do Flume
ADD configs/flume/* $FLUME_HOME

# Copia os arquivos de configurações para o Spark
RUN cp $HADOOP_HOME/etc/hadoop/core-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml $SPARK_HOME/conf/

# Corrigi o bug causado pelo log4j no Hive
RUN rm $HIVE_HOME/lib/log4j-slf4j-impl-2.10.0.jar

# Corrigi o bug do guava no Hive
RUN rm $HIVE_HOME/lib/guava-19.0.jar
RUN cp $HADOOP_HOME/share/hadoop/hdfs/lib/guava-27.0-jre.jar $HIVE_HOME/lib/

# Corrigi o bug do guava no Flume
RUN rm $FLUME_HOME/lib/guava-11.0.2.jar

# Copia os arquivo de inicialização do projeto para a container
ADD configs/start-master.sh start-master.sh

# Inicia o schema do Derby que será utilizado pelo Hive
RUN $HIVE_HOME/bin/schematool -dbType derby -initSchema

# Por só aceitar um CMD no container essa linha sobrescreve o comando a ser rodado definido no slave
CMD bash start-master.sh