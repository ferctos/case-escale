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

A query abaixo apresenta o relatório de ticket médio, seja por vendas (Total de faturamento em relação ao número de clientes distintos) quanto por ligações (Total de faturamento em relação ao número de ligações distintas).

```sql
with media_infos as (
    select
        lm.midia,
        count(distinct a.customer_id) as num_customers,
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
    round((total_amount / num_customers)::numeric, 2) as sales_avg_ticket,
    round((total_amount / num_calls)::numeric, 2) as calls_avg_ticket
from media_infos
order by 1 asc 
```