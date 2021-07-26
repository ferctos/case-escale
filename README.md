# Case Técnico Escale - Senior Analytics Engineer

A página em questão busca apresentar respostas e abordagens de solução relacionadas ao case técnico proposto para a vaga de **Senior Analytics Engineer** da Escale. 

## Parte 1 - Respostas usando SQL 

Nesta seção apresentamos as queries utilizadas para a elucidação das respostas às perguntas realizadas pelo Negócio com base no modelo de dados vigente para a estrutura de Atendimento.

### Pergunta 1: Qual foi o número de ligações distintas e a média da duração das ligações por dia?

A query estruturada abaixo apresenta o relatório diário de ligações distintas, bem como a sua duração média.

```sql
select
    created_at::date as day,
    count(distinct id) as distinct_calls,
    round(avg(duration)) as avg_call_duration
from call_history_queue
group by 1
order by 1 asc
```

### Pergunta 2: Qual o percentual de ligações de cada atendente em relação ao seu time?

A query estruturada abaixo apresenta o relatório de produtividade dos(as) atendentes em relação ao total de ligações atribuídas aos seus respectivos times.

```sql
with team_calls as (
    select
        team_id,
        count(distinct id) as team_calls
    from call_history_queue
    where team_id is not null
    group by 1
),

agent_calls as (
    select
        team_id,
        user_id as agent_id,
        count(distinct id) as agent_calls
    from call_history_queue
    where user_id is not null
    group by 1, 2
)

select
    tc.team_id,
    ac.agent_id,
    round(((ac.agent_calls / tc.team_calls::float) * 100)::numeric, 2) as pct_agent_team_calls
from agent_calls ac
join team_calls tc on ac.team_id = tc.team_id
order by 1 asc, 3 desc
```

### Pergunta 3: Qual o ticket médio das vendas e das ligações, por mídia?

A query abaixo apresenta o relatório de ticket médio, seja por vendas (Casos em que o campo `type_id` da tabela `attendances` for igual a 1) quanto pelo total de ligações.

```sql
with media_infos as (
    select
        lm.midia,
        count(distinct case when a.type_id = 1 then chq.id else null end) as num_sales_calls,
        count(distinct chq.id) as num_calls,
        sum(a.monthly_value) as total_amount
    from call_history_queue chq
    join lines_mkt_final lm on chq.lines_id::text = lm.line_id
    join attendances_calls ac on chq.token = ac.token
    join attendances a on ac.attendance_id = a.id
    group by 1
)

select
    midia,
    round((total_amount / num_sales_calls)::numeric, 2) as sales_avg_ticket,
    round((total_amount / num_calls)::numeric, 2) as calls_avg_ticket
from media_infos
order by 1 asc
```

## Parte 2 - Apresentação da Plataforma 

A arquitetura escolhida para a modelagem das tabelas baseia-se em ferramentas open-source que vem ganhando notoriedade e ampla adoção em diversos times de Data Engineering e/ou Analytics Engineering, a saber:

* **Airbyte**: Ferramenta usada para as etapas de Extração **(E)** e Load **(L)** em um paradigma de pipelines do tipo **ELT**. Como principais pontos fortes incluem-se a capacidade de definirmos origens, destinos e agendamento de extrações diretamente por uma UI de fácil entendimento, havendo também a capacidade de definir a ingestão por meios **full load** ou **incrementais**. Em nosso cenário, será responsável por extrair os dados das tabelas existentes no Postgres e armazená-las no BigQuery para as etapas de transformação e geração dos modelos que serão expostos ao self-service.

* **DBT**: Ferramenta amplamente utilizada para realização de transformações diretamente no Data Warehouse, permitindo que times de Analytics Engineering possam executar tais transformações através de SQL e mantendo boas práticas de Engenharia de Software, tais como testes, controle de versões e documentação. Em nosso cenário, utilizaremos a ferramenta para a transformação dos dados brutos a fim de criarmos o modelo físico que atenderá as principais perguntas tidas pelo negócio. 

* **Metabase**: Ferramenta de visualização e geração de relatórios self-service em BI/Dados que ganhou bastante popularidade nos últimos anos. Utilizaremos em nosso cenário para gerar métricas relevantes ao negócio, bem como para responder a perguntas relevantes. 

Para gerarmos o cenário, utilizamo-nos também do **Terraform** para a criação dos recursos citados no Google Cloud Platform, que por sua vez foi a plataforma de nuvem escolhida para a apresentação. Por questões de adoção em nuvem, utilizaremos o **BigQuery** como nossa solução de Data Warehousing. 

## Parte 3 - Configuração do Ambiente

Para provisionarmos o ambiente utilizado na apresentação, é necessária a instalação dos utilitários citados abaixo:

* [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* [Gcloud CLI](https://cloud.google.com/sdk/docs/quickstart-macos)

Uma vez que ambos estejam instalados, é necessária a inicialização do ambiente de interação com o Google Cloud Platform via linha de comando, por meio dos comandos citados abaixo:

```sh
gcloud init
gcloud auth application-default login
```

Em seguida, será preciso criar o arquivo `terraform.tfvars` na raiz do projeto. Este arquivo receberá as principais variáveis relativas à conta do GCP sob a qual os recursos serão criados. Segue abaixo o molde de criação deste arquivo:

```
# The GCP Billing ID from the first step
billing_id = "######-######-######"

# The GCP folder ID of where you want your project to be under
# Leave this blank if you use a personal account
folder_id = ""

# The GCP organization ID of where you want your project to be under
# Leave this blank if you use a personal account
org_id = ""

# The GCP project to create
project_id = ""
```

Por fim, podemos subir o ambiente por meio do caminho `make up`. Outros comandos relacionados ao gerenciamento do ambiente criado podem ser consultados diretamente através do `Makefile`. 

## Parte 4: Remodelagem dos Dados 

O modelo de vigente possui algumas características que o tornam inadequado para utilização contínua por parte dos times de Analytics e/ou Business, o que nos leva à necessidade de propor um novo modelo que atenda a estas necessidades:

* Alta quantidade de JOINs a ser executados entre as tabelas para obter as métricas mais relevantes
* Duplicidade de informações entre diferentes tabelas, o que pode levar a conclusões confusas e/ou errôneas por parte dos(as) analistas

O novo modelo de dados surge com a proposta de atacar estes problemas diretamente, trazendo portanto uma estrutura composta por três tabelas de fácil aderência e interpretabilidade no seu uso do dia-a-dia por parte dos(as) analistas:

* **attendance.call_history**: Apresenta os principais detalhes das ligações, bem como as principais métricas associadas a elas.
* **attendance.marketing_details**: Apresenta os detalhes das campanhas associadas com as ligações, servindo como ponto de ligação para casos em que necessitamos ter um maior entendimento de performance por canais e/ou campanhas individualmente. 
* **attendance.attendance_details**: Apresenta os detalhes dos atendimentos atrelado às ligações, sendo útil para casos em que necessitamos ter um entendimento mais amplo da performance de times e/ou atendentes, ou quando desejamos realizar estudos sobre os consumidores, por exemplo.

O pipeline de construção do novo modelo é realizado sob o paradigma **ELT** utilizado em plataformas de dados modernas no qual os processos de extração e ingestão ocorrem anteriormente, deixando a transformação dos dados para a parte final que ocorrerá diretamente no Data Warehouse. Em nosso cenário, o **DBT** é a ferramenta responsável por descrever e realizar as transformações requeridas para a geração do novo modelo. 

Maiores detalhes a respeito dos schemas e/ou descrições das novas colunas podem ser encontrados diretamente no arquivo `dbt/models/schema.yml`. 

## Parte 5: Respondendo a perguntas através do novo Modelo

Conseguimos demonstrar o uso do novo modelo através de algumas queries de exemplo utilizadas para responder a duas perguntas realizadas:

### Pergunta 1: Número de ligações receptivas diárias por status final da ligação e tipo de mídia

```sql
select
    extract(date from a.call_created_at) as day,
    a.call_final_status,
    b.media_type,
    count(distinct a.call_id) as num_calls
from attendance.call_history a
left join attendance.marketing_details b on a.mkt_id = b.mkt_id
where a.call_status = 'Entrada'
group by 1, 2, 3
order by 1 asc, 2 asc, 3 asc, 4 desc
```

### Pergunta 2: Número de ligações não receptivas mensais por tipo de mídia

```sql
select
    format_datetime("%B, %Y", a.call_created_at) as month,
    b.media_type,
    count(distinct a.call_id) as num_calls
from attendance.call_history a
left join attendance.marketing_details b on a.mkt_id = b.mkt_id
where a.call_status <> 'Entrada'
group by 1, 2
order by 1 asc, 2 asc, 3 desc
```





