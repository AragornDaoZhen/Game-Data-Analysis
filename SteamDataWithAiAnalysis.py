# -*- coding: utf-8 -*-

import requests
import csv
import time
from datetime import datetime
import openai
import json



def get_steam_reviews(appid, max_requests=10):
    base_url = "https://store.steampowered.com/appreviews/"     # 使用Steam官方提供的API接口
    # https://partner.steamgames.com/doc/webapi_overview
    params = {
    #   https://partner.steamgames.com/doc/store/getreviews
        # 可以通过参数选推荐或不推荐的评测，详见api文档
        "json": 1,
        "filter": "all",  # recent – 以创建时间排序，all – （默认）以值得参考的程度排序，基于 day_range 参数作为滑动窗口，总是找到可返回的结果。
        "language": "english",  # 评价语言，简体中文：schinese 英文：english   all取得所有评测
        "day_range": 180,     # 	从现在至 N 天前，查找值得参考的评测。 仅适用于“all” 筛选器。 最大值为 365。
        "cursor": "*",  # 分页游标
        "num_per_page": 100  # 每次请求最大数量
    }

    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Referer": f"https://steamcommunity.com/app/{appid}/reviews/"
    }

    all_reviews = []
    request_count = 0

    current_time = datetime.now()
    current_time_formatted = current_time.strftime("%Y-%m-%d_%H-%M-%S")
    csvName = f"steam_reviews_{appid}_{current_time_formatted}.csv"


    with open(csvName, 'w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f)
        writer.writerow(['评测时间'
                            , '评测游戏时长(小时)'
                            , '推荐与否'
                            , '评测内容'
                            , '有帮助数'
                            , '系统予以的评测权重'
                            , 'steamid'
                            , '此游戏总游玩时长(小时)'
                            , "拥有游戏数量"
                         ])

        while request_count < max_requests:
            try:
                response = requests.get(f"{base_url}{appid}", params=params, headers=headers)
                response.raise_for_status()
                data = response.json()

                # current_time_formatted = current_time.strftime("%Y-%m-%d_%H-%M-%S")# 调试
                # jsonName = f"dataReview_{appid}_{current_time_formatted}.json"# 调试
                # with open(jsonName, 'w', encoding='utf-8') as f:    # 调试
                #     json.dump(data, f, ensure_ascii=False, indent=4)# 调试

                for review in data['reviews']:
                    review_data = [
                        datetime.fromtimestamp(review['timestamp_created']).strftime('%Y-%m-%d %H:%M'),
                        round(review['author']['playtime_at_review'] / 60, 1),
                        '推荐' if review['voted_up'] else '不推荐',
                        review['review'].replace('\n', ' ').strip()
                        , review['votes_up']
                        , review['weighted_vote_score']
                        , review['author']['steamid']
                        , round(review['author']['playtime_forever'] / 60, 1)
                        , review['author']['num_games_owned']
                    ]
                    writer.writerow(review_data)
                    all_reviews.append(review_data)
                    print(review_data)  # 调试

                if not data['cursor'] or data['cursor'] == params['cursor']:    # 更新游标
                    break

                params['cursor'] = data['cursor']
                request_count += 1
                time.sleep(3 + request_count * 0.5) # 保守延迟策略

            except Exception as e:
                print(f"请求失败: {str(e)}")
                break

    print(f"已保存{len(all_reviews)}条评价到steam_reviews.csv")
    return all_reviews


def AI_analyze_reviews(reviews):
    """使用AI分析差评原因"""
    # 筛选不推荐评价
    negative_reviews = [r[3] for r in reviews if r[2] == '不推荐']

    if not negative_reviews:
        print("未找到差评数据")
        return

    # 构建分析提示（限制分析前100条防止过量）
    sample_reviews = negative_reviews[:100]
    prompt = f"""请分析以下游戏差评，总结主要问题类型（用中文回答）：

    评价样本：
    {sample_reviews}

    请按此格式回复：
    1. 主要问题分类（如性能优化、内容不足等）
    2. 每个分类的代表性差评示例
    3. 总结出现频率最高的问题"""

    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        print("\nAI分析结果：\n")
        print(response.choices[0].message['content'])

        with open('analysis_result.txt', 'w', encoding='utf-8') as f:
            f.write(response.choices[0].message['content'])

    except Exception as e:
        print("AI分析失败:", str(e))


# if __name__ == "__main__":



    # 这输入————————————————————————————————————————

appid = 2527500     # Steam游戏ID    2527500 米塔
max_requests = 10   # 最大请求次数（保守些，不要太多。每次大约100条评论。详见steam api文档）
use_AI = 0       # 是否使用GPT分析，0为不使用，1为使用
openai.api_key = 'None314159'  # GPT的API密钥

# 输出csv文件，使用ai时还输出txt文件，注意文件保存位置

    # 这输入————————————————————————————————————————



'''
后续可改进：
1. 要大范围大规模多语言的分析还是要借助AI，并且可选择不同AI。思路是让AI整理出每条好评和差评的标签，然后依据玩家的评测权重（可以自己定义）
给标签加权，最终输出标签分布图
2. 可以通过时间轴在另一方面建立舆情库（需要定期从内容平台和媒体平台等整理舆情数据。可以是定期使用不同搜索引擎搜索相关网页，归到时间轴上定性定量），
然后与评测相关数据进行匹配，分析评测与舆情的关系
3. 另一个比较费力但实操性更好的方案是让AI仅用于翻译不同语言的评测然后输出。分析人员依然是有必要阅读每一条评论的，比如黑猴有条差评是玩家有光敏癫痫，
反映游戏对生理缺陷玩家的考虑不够，这对于英语地区玩家比较敏感，并且评测有较高的点赞和权重，但所有AI总结都没有提到这个评测的情况

其他：
1. 可否直接prompt给AI去分析指定游戏的差评？目前来说AI不会像这里通过api拉取一圈信息后再分析，而是直接搜索相关网页（比如游侠网、搜狐网等等）提炼总结，
即通过多手来源信息而不是一手的评测信息来输出结果，不过之后的AI可能会自行评估和搭建最优成效的工作流
2. 关于AI的运用：对于这里的工作，建议是借助AI的语义分析能力，而最优工作流的评估与搭建还是需要人
'''



reviews = get_steam_reviews(appid, max_requests=10)
if use_AI == 1:
    if reviews:
        AI_analyze_reviews(reviews)
    else:
        print("没有获取到评价数据")
else:
    print("未使用AI分析")
