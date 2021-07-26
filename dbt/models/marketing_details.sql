with marketing_details as (
    select
        cast(line_id as integer) as mkt_id,
        midia as media_type,
        campanha as campaign_name,
        fonte as origin_type,
        pagina as campaign_page,
        dominio as campaign_origin_domain,
        destino as campaign_destiny,
        operacao as campaign_operation,
        growth as activation_type,
        cast(created_at as timestamp) as mkt_details_created_at
    from raw.lines_mkt_final
)

select * from marketing_details