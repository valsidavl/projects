-- LTV
select
    platform,
    device_os,
    country,
    g_medium, 
    if(g_medium = 'referral', g_medium, g_source) g_source,
 	multiIf(g_campaign like '%brand%','brand',g_campaign like '%avod%','avod',g_campaign like '%svod%','svod','und') g_campaign_new,
 	g_campaign,
    g_content,
    svod_type,
    age,
    attribution_days,
    cohort_start as cohort_start_month,
    svod_month as svod_month,
    cohort_age,
    sumIf(revenue,is_cohort_user = 1) revenue,
    uniq(master_uid) cohort_size,
    uniqIf(master_uid, is_cohort_user = 1) current_users
from
    (
    select
        platform,
        device_os,
        country,
        argMax(utm_medium, rocket_dt) g_medium,
        argMax(utm_source, rocket_dt) g_source,
        argMax(utm_campaign, rocket_dt) g_campaign,
        argMax(utm_content, rocket_dt) g_content,
        target_action as svod_type,
        cohort_start,
        svod_month,
        cohort_age,
        arrayElement(subscription_debit_month_revenue,toUInt8(cohort_age)+1) revenue,
        cpc_uv.master_uid,    
        is_cohort_user,
        multiIf(dateDiff('day', cpc_uv.rocket_dt, conv.debit_date) <= 1, 1,
        		dateDiff('day', cpc_uv.rocket_dt, conv.debit_date) <= 7,  7,
        		dateDiff('day', cpc_uv.rocket_dt, conv.debit_date) <= 30,  30,-1) attribution_days,
        age
    from
        (
        select
        distinct
        master_uid,
        If(age_90 = 'current' and age_30 ='new','30','90') age,
        platform,
        If(device_os NOT IN  ('СПИСОК НУЖНЫХ УСТРОЙСТВ'), 'Other',device_os) device_os,
        country,
        rocket_dt,
        utm_medium,
        utm_campaign,
        utm_source,  
        utm_content  
        from vmachinskiy.ltv_all
        where 
        age_30 = 'new' and 
        rocket_dt >= toStartOfMonth(date_sub(MONTH,1,toDate('{d1}'))) and rocket_dt < toStartOfMonth(date_sub(MONTH,-1,toDate('{d1}'))) 
        and (
---------ФИЛЬТР ПО ИСТОЧНИКУ ТРАФИКА 
        )
        ) cpc_uv
    all inner join 
        ( 
        select distinct 
            *,
            min_cohort_start_dt + arrayJoin(range(toUInt32(dateDiff('day', min_cohort_start_dt, today())/30)+1))*30 as svod_date,
            toStartOfMonth(svod_date) as svod_month,
            dateDiff('day', min_cohort_start_dt, svod_date) / 30 cohort_age, 
            svod_date < finish_date as is_cohort_user 
        from
            (
            select
                user_id,
                subscription_debit_month_revenue,
                subscription_chain_num,
                argMin(platform, cohort_start_dt) platform, 
                argMin(device_os, cohort_start_dt) device_os,
                min(cohort_start) cohort_start, 
                min(cohort_start_dt) as min_cohort_start_dt,
                min(debit_date) as debit_date,
                max(finish_date) as finish_date, 
                argMin(target_action, cohort_start_dt) as target_action
            from
            (
            select
                _platform as platform,
                _device_os as device_os,
                user_id,
                _subscription_chain_num as subscription_chain_num,
                _cohort_start as cohort_start, 
                _cohort_start_dt as cohort_start_dt,
                _debit_date as debit_date,
                _finish_date as finish_date, 
                _target_action as target_action,	
                _subscription_debit_month_revenue as subscription_debit_month_revenue
            from
                (
                select
                    user_id,
                    groupArray(platform) _platform, 
                    groupArray(If(device_os NOT IN  ('СПИСОК НУЖНЫХ УСТРОЙСТВ'), 'Other',device_os)) _device_os,
                    groupArray(cohort_start) _cohort_start,
                    groupArray(cohort_start_dt) _cohort_start_dt, 
                    groupArray(debit_date) _debit_date,
                    groupArray(finish_date) _finish_date,
                    groupArray(target_action) _target_action,
                    arrayEnumerate(_cohort_start) index,
                    arrayCumSum( x -> x = 1 or _debit_date[x] >= _finish_date[x-1] + 7, index 
                        ) _subscription_chain_num ,
                    groupArray(subscription_debit_month_revenue) _subscription_debit_month_revenue
                from
                    (
                    select distinct 
                        dictGetStringOrDefault('classified_subsite', 'platform', toUInt64(subsite_id), 'und') platform,
                        dictGetString('classified_subsite','device_os',toUInt64(subsite_id)) as device_os,
                        user_id,
                        toDate(debit_reportable_time) debit_date,
                        toDate(debit_finish_time) finish_date,
                        purchase_id,
                        multiIf(certificate_id > 0, 'certificate', trial_id <> 0 and debit_kind_id = 1, 'SVOD trial', 'SVOD purchase') target_action, 
                        if(trial_id <> 0 and debit_kind_id = 1, toStartOfMonth(toDate(debit_date)), toStartOfMonth(debit_date)) cohort_start,
                        if(trial_id <> 0 and debit_kind_id = 1, toDate(debit_date), debit_date) cohort_start_dt,
                        debit_b2c subscription_debit_month_revenue
                    from
---------           ТАБЛИЦА ПЛАТЕЖНЫХ ОПЕРАЦИЙ
                    where
                        toDate(debit_reportable_time_raw)>= toStartOfMonth(date_sub(MONTH,1,toDate('{d1}'))) 
                        and object_id in (6, 107, 109) 
                        and dictGetString('profit_payment_system','method',toUInt64(ps_id)) <> 'external' 
                        and dictGetString('classified_subsite', 'partner', toUInt64(subsite_id))= ''
                        and purchase_kind = 'SVOD'
                    order by
                        platform,
                        device_os,
                        user_id,
                        debit_date,
                        finish_date 
                    )
                group by
                    user_id
                ) 
            array join 
                _platform,
                _device_os,
                _cohort_start,
                _cohort_start_dt,
                _debit_date,
                _finish_date,
                _target_action,
                index,
                _subscription_chain_num
            )   
            group by
                user_id,
                subscription_chain_num,
                subscription_debit_month_revenue
            having
                target_action <> 'certificate' 
                and cohort_start >= toStartOfMonth(toDate('{d1}')) and cohort_start < toStartOfMonth(date_sub(MONTH,-1,toDate('{d1}')))
            )
        ) conv 
    on
         cpc_uv.master_uid = conv.user_id
    where
        cpc_uv.rocket_dt <= conv.debit_date
        and dateDiff('day', cpc_uv.rocket_dt, conv.debit_date) <= 30 
    group by 
        platform,
        device_os,
        country,
        target_action as svod_type,
        cohort_start,
        svod_month,
        cohort_age,
        cpc_uv.master_uid,
        is_cohort_user,
        age,
        subscription_debit_month_revenue,
        attribution_days
    )
group by
    platform,
    device_os,
    g_campaign,
    attribution_days,
    age,
    g_content,
    country,
    g_medium,
    g_source,
    svod_type,
    cohort_start_month,
    svod_month,
    cohort_age
