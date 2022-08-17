with main as
(with 
users_with_installs as
(
    select distinct random_user_id as install_users,floor(created_at/86400)-18900 as time_install from fitness-296913.Fitcher_us.all
    where app_version_short = '3.0.0' and activity_kind = 'install' 
),
users_wih_firstlaunch as 
(
    select distinct random_user_id as firstlaunch_users from fitness-296913.Fitcher_us.all
    where app_version_short = '3.0.0' and event_name = 'firstlaunch' 
),
users_wih_onboard as 
(
    select distinct  random_user_id as onboard_users from fitness-296913.Fitcher_us.all
    where app_version_short = '3.0.0' and event_name like  '%onboard%' 
)

select * from users_with_installs a left join users_wih_firstlaunch b on a.install_users=b.firstlaunch_users left join users_wih_onboard c  on a.install_users=c.onboard_users),
install_firstlaunch_onboard as
(
    select time_install,count(*) as install_firstlaunch_onboard_count from main  
    where install_users is not null  and firstlaunch_users is not null and onboard_users is not null
    group by time_install
),
install_onboard as 
(
    select time_install,count(*) as install_onboard_count from main  
    where install_users is not null and firstlaunch_users is null and onboard_users is not null
    group by time_install
),
install_firstlaunch as
(
    select time_install,count(*) as install_firstlaunch_count from main  
    where install_users is not null  and firstlaunch_users is not null and onboard_users is null
    group by time_install
),
install as
(
    select time_install,count(*) as install_only_count from main  
    where install_users is not null and firstlaunch_users is null and onboard_users is null
    group by time_install
) 
select a.time_install,install_only_count+install_firstlaunch_count+install_onboard_count+install_firstlaunch_onboard_count as install_count,
install_only_count,install_firstlaunch_count,install_firstlaunch_onboard_count,install_onboard_count  from install a left join install_firstlaunch_onboard b on a.time_install = b.time_install 
left join install_onboard c on a.time_install = c.time_install
left join install_firstlaunch d on a.time_install = d.time_install
order by time_install desc
