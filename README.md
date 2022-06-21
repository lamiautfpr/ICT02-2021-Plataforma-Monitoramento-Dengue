# ICT02-2021-Plataforma-Monitoramento-Dengue

Arquitetura completa Hadoop com Spark, Flume e Hive.

------------------
### Como Utilizar 

Clone o repositório.
```git clone git@github.com:lamiautfpr/ICT02-2021-Plataforma-Monitoramento-Dengue.git```

Suba os container de modo detached.
```docker compose up -d```

Para derrubar os containers rode
```docker compose down```

------------------
### Configurações úteis

###### docker-compose.yaml

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