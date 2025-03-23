SELECT
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new1' THEN app_uid END) AS 开始加载,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new2' THEN app_uid END) AS 完成加载,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new3' THEN app_uid END) AS 创建角色,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new4' THEN app_uid END) AS 开始片头,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new5' THEN app_uid END) AS 完成片头,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new6' THEN app_uid END) AS 第一引导,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new7' THEN app_uid END) AS 第二引导,
  COUNT(DISTINCT CASE WHEN param_str_3 = 'new8' THEN app_uid END) AS 第三引导
FROM (
  SELECT 
    param_str_3, 
    app_uid 
  FROM '事件表' -- 需指定为真实表名
  WHERE created_at BETWEEN '2024-12-01' AND '2025-03-13'
		AND country_code = 'US'
    AND event_id = 108  -- 事件表的新手引导筛选条件，节约计算量
    AND param_str_3 IN ('new1','new2','new3','new4','new5','new6','new7','new8')
  GROUP BY param_str_3, app_uid  -- 预先去重
) t;