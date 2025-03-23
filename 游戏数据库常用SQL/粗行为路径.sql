SELECT
        DISTINCT
        app_at AS `应用时间`
        ,app_uid AS UID
        ,param_str_3 AS `资源类型`
        ,param_str_4 AS `变更对象`
        ,param_int_5 AS `变更数量`
        ,param_str_6 AS `变更原因`
        ,app_run_id AS `运行ID`
        ,app_version AS `实时版本`
        ,param_int_1 AS `实时资源1`
        ,param_int_2 AS `实时资源2`
        ,param_int_3 AS `实时等级`
        ,param_int_4 AS `实时资源4`
        ,app_progress AS `实时进度`
        ,param_str_1 AS `实时场景`
        ,param_str_2 AS `实时弹窗`
        ,ip
FROM '事件表' -- 请替换为实际的事件表名
WHERE 
        app_uid = '{{uid}}'
    AND created_at >= '{{ dateRange.start }}' AND created_at <= DATE_ADD('{{ dateRange.end }}', INTERVAL 3 DAY)
        AND app_at >= '{{dateRange.start}}' AND app_at <= '{{dateRange.end}}'
        AND event_id = 102
ORDER BY app_at DESC
LIMIT 3000  -- 请根据需要调整返回结果的条数
