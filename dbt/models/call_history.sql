with call_history as (
    select
        cast(id as integer) as call_id,
        cast(lines_id as integer) as mkt_id,
        token as attendance_token,
        cast(queue_log_modality_types_id as integer) as call_status_id,
        cast(queue_log_verb_types_id as integer) as call_final_status_id,
        wait as wait_time,
        duration as duration_time,
        duration_pos_attendance as duration_pos_attendance_time,
        cast(created_at as timestamp) as call_created_at
    from raw.call_history_queue
),

telephony_types as (    
    select
        cast(id as integer) as id,
        description as description_status
    from raw.telephony_types
)

select 
    a.call_id,
    a.mkt_id,
    a.attendance_token,
    b.description_status as call_status,
    c.description_status as call_final_status,
    a.wait_time,
    a.duration_time,
    a.duration_pos_attendance_time,
    a.call_created_at
from call_history a 
left join telephony_types b on a.call_status_id = b.id
left join telephony_types c on a.call_final_status_id = c.id