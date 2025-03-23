WITH registered_users AS (
    SELECT 
        device_id,
        CAST(reg_at AS DATE) AS reg_date  -- 注册日期（去时间部分）
    FROM '玩家表' -- user表，非活跃表，主要获取注册时间，需要指定

    WHERE reg_at IS NOT NULL              -- 确保有注册日期

-- 筛选条件在此处修改

	    AND reg_at >= '2024-12-01'        -- 筛选注册时间
        AND reg_at <= '2025-03-13'
        AND (pay_sm_money > 0 OR pay_sm_money IS NOT NULL)  -- 筛选为付费玩家，去掉此行即为所有玩家
        AND country_code = 'US'
		AND channel = 'iOS'
        AND network = 'Facebook'

        -- 需手动聚合为同期群成熟的数据，这方面sql后续可改进
        


),
active_events AS (
    SELECT 
        o.device_id,
        CAST(o.reported_at AS DATE) AS login_date  -- 活跃日期（去时间部分）
    FROM '活跃表' o   -- 需要指定
    INNER JOIN registered_users r          -- 内关联保证只保留有注册的玩家
        ON o.device_id = r.device_id
    WHERE o.reported_at IS NOT NULL        -- 确保有活跃日期
        AND event_id = 2001 -- 应用服务器活跃玩家快照同步事件，节约查询计算量
),
retention_data AS (
    SELECT 
        r.reg_date,
        a.login_date,
        r.device_id,
        DATEDIFF(a.login_date, r.reg_date) AS retention_day  -- 计算留存天数差
    FROM registered_users r
    LEFT JOIN active_events a
        ON r.device_id = a.device_id
)
SELECT
    reg_date AS 注册日期,
    COUNT(DISTINCT device_id) AS 注册玩家数,
    COUNT(DISTINCT CASE WHEN retention_day = 1 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 次留,
    COUNT(DISTINCT CASE WHEN retention_day = 2 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 2留,
    COUNT(DISTINCT CASE WHEN retention_day = 3 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 3留,
    COUNT(DISTINCT CASE WHEN retention_day = 7 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 7留,
    COUNT(DISTINCT CASE WHEN retention_day = 14 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 14留,	
    COUNT(DISTINCT CASE WHEN retention_day = 30 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 30留,
    COUNT(DISTINCT CASE WHEN retention_day = 60 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 60留,
    count(DISTINCT CASE WHEN retention_day = 90 THEN device_id END) 
         / COUNT(DISTINCT device_id) AS 90留
FROM retention_data
GROUP BY reg_date
ORDER BY reg_date;
