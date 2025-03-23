WITH
-- 获取所有注册玩家
registered_users AS (
    SELECT 
        device_id,
        CAST(reg_at AS DATE) AS reg_date
    FROM '玩家表' --user表，非活跃表，需要指定
    WHERE reg_at IS NOT NULL
				AND country_code = 'US'    -- 地区
				AND pay_money > 0 -- 限定付费
				AND channel = 'iOS' -- 限定渠道
                AND network = 'Facebook'
				AND reg_at >= '2025-02-17' AND reg_at < '2025-03-17' -- 限定注册时间
),

-- 提取每个玩家各等级的首次到达时间
level_achievements AS (
    SELECT 
        o.device_id,
        o.param_int_4 AS game_level,
        CAST(o.reported_at AS DATE) AS achieve_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.device_id, o.param_int_4 
            ORDER BY o.reported_at
        ) AS rn
    FROM '事件表' o -- 需要指定
    INNER JOIN registered_users r 
        ON o.device_id = r.device_id
    WHERE 
        o.param_int_4 > 0  -- 过滤无效等级
				AND event_id = 2001 -- 应用服务器活跃玩家快照同步事件
),

-- 筛选每个等级的首次到达记录
first_achievements AS (
    SELECT 
        device_id,
        game_level,
        achieve_date
    FROM level_achievements
    WHERE rn = 1  -- 每个等级只取首次达成
),

-- 计算各等级所需天数
level_days AS (
    SELECT 
        f.device_id,
        f.game_level,
        DATEDIFF(f.achieve_date, r.reg_date) AS days_to_achieve
    FROM first_achievements f
    INNER JOIN registered_users r 
        ON f.device_id = r.device_id
)

-- 聚合计算结果
SELECT 
    game_level AS 等级,
    COUNT(DISTINCT device_id) AS 达到人数,
    AVG(days_to_achieve) AS 平均天数,
    MAX(days_to_achieve) AS 最长天数,
    MIN(days_to_achieve) AS 最短天数
FROM level_days
WHERE days_to_achieve >= 0  -- 过滤异常值
GROUP BY game_level
ORDER BY game_level;