with call_history as (
    select
        token as attendance_token,
        cast(team_id as integer) as team_id,
        cast(user_id as integer) as attendant_id,
        cast(ddd as integer) as customer_ddd,
        phone as customer_phone,
        locality as customer_locality,
        uf as customer_uf
    from raw.call_history_queue
),

attendances_calls as (
    select 
        cast(id as integer) as attendance_detail_id,
        cast(attendance_id as integer) as attendance_id,
        token as attendance_token,
        cast(queue_number as integer) as queue_number,
        cast(main_connection as integer) as main_connection,
        cast(created_at as timestamp) as attendance_created_at
    from raw.attendances_calls
),

attendances as (
    select
        cast(id as integer) as attendance_id,
        cast(customer_id as integer) as customer_id,
        cast(protocol as string) as attendance_protocol,
        cast(status_id as integer) as attendance_status_id,
        cast(type_id as integer) as attendance_type_id,
        monthly_value
    from raw.attendances
)

select 
    b.attendance_detail_id,
    b.attendance_id,
    a.attendance_token,
    a.team_id,
    a.attendant_id,
    b.queue_number,
    b.main_connection,
    c.attendance_protocol,
    c.attendance_status_id,
    c.attendance_type_id,
    c.customer_id,
    a.customer_ddd,
    a.customer_phone,
    a.customer_uf,
    a.customer_locality,
    b.attendance_created_at
from attendances_calls b
left join call_history a on a.attendance_token = b.attendance_token
left join attendances c on b.attendance_id = c.attendance_id