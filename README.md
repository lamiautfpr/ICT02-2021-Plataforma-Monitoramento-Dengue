# ICT02-2021-Plataforma-Monitoramento-Dengue

Arquitetura completa Hadoop com Spark, Flume e Hive.

------------------
## Como Utilizar 

Para clonar o repositório é necessário ter o [Git LFS](https://git-lfs.github.com/) instalado.  
Para fazer a instalação siga os passo em https://github.com/git-lfs/git-lfs/wiki/Installation  
Para mais duvida acesse https://docs.github.com/pt/repositories/working-with-files/managing-large-files/  

Clone o repositório.  
```git clone git@github.com:lamiautfpr/ICT02-2021-Plataforma-Monitoramento-Dengue.git```

Suba os container de modo detached.  
```docker compose up -d```

Para derrubar os containers rode  
```docker compose down```

------------------
## Configurações úteis

### docker-compose.yaml

Para aumentar o número de slaves duplique esse codigo dentro do arquivo e renomeie todas as ocorencias de `slave1` para `slavex` on `x` é o numero do novo slave,
```yaml
  slave1:
    build:
      context: .
      target: slave
    container_name: hadoop-slave1
    hostname: hadoop-slave1
    depends_on:
      - master
    volumes:
      - ./data/slave1:/app/data
```