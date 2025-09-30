import httpx
import asyncio
import pytest
import time

# List of characters to test
CHARACTERS = [
    "月",
    "水",
    "火",
    "木",
    "金",
    "土",
    "天",
    "地",
    "人",
    "心",
    "手",
    "足",
    "眼",
    "耳",
    "口",
    "鼻",
    "頭",
    "身",
    "山",
    "河",
    "海",
    "風",
    "雨",
    "雪",
    "花",
    "草",
    "樹",
    "鳥",
    "魚",
    "虫",
    "狗",
    "貓",
    "牛",
    "馬",
    "羊",
    "豬",
    "雞",
    "鴨",
    "鵝",
    "虎",
    "獅",
    "象",
    "猴",
    "熊",
    "鹿",
    "兔",
    "鼠",
    "蛇",
    "龍",
    "鳳",
    "家",
    "房",
    "門",
    "窗",
    "桌",
    "椅",
    "床",
    "書",
    "筆",
    "紙",
    "刀",
    "劍",
    "弓",
    "箭",
    "車",
    "船",
    "飛",
    "機",
    "電",
    "話",
    "光",
    "影",
    "聲",
    "音",
    "色",
    "香",
    "味",
    "觸",
    "冷",
    "熱",
    "乾",
    "濕",
    "軟",
    "硬",
    "重",
    "輕",
    "大",
    "小",
    "長",
    "短",
    "高",
    "低",
    "寬",
    "窄",
    "厚",
    "薄",
    "新",
    "舊",
    "好",
    "壞",
    "美",
    "醜",
    "善",
    "惡",
    "真",
    "假",
    "對",
    "錯",
    "是",
    "否",
    "有",
    "無",
    "多",
    "少",
    "全",
    "空",
    "滿",
    "缺",
    "始",
    "終",
    "前",
    "後",
    "左",
    "右",
    "上",
    "下",
    "內",
    "外",
    "東",
    "西",
    "南",
    "北",
    "中",
    "央",
    "邊",
    "角",
    "圓",
    "方",
    "直",
    "彎",
    "平",
    "斜",
    "深",
    "淺",
    "遠",
    "近",
    "快",
    "慢",
    "早",
    "晚",
    "今",
    "昨",
    "明",
    "年",
    "月",
    "週",
    "日",
    "時",
    "分",
    "秒",
]

API_URL = "http://localhost:8000/user/wrong-words"  # Updated endpoint for wrong words
USER_ID = "00000000-0000-0000-0000-000000000000"  # Use a valid UUID string


async def add_wrong_word(client, word):
    payload = {"user_id": USER_ID, "word": word}
    response = await client.post(API_URL, json=payload)
    return response.status_code, response.json() if response.content else None


@pytest.mark.asyncio
async def test_add_wrong_words_volume_stress():
    async with httpx.AsyncClient(timeout=10) as client:
        start_time = time.perf_counter()
        tasks = [add_wrong_word(client, char) for char in CHARACTERS]
        results = await asyncio.gather(*tasks)
        elapsed = time.perf_counter() - start_time
    # Print or assert results
    success, fail, conflict = 0, 0, 0
    for idx, (status, resp) in enumerate(results):
        print(f"{CHARACTERS[idx]}: status={status}, response={resp}")
        if status in (200, 201):
            success += 1
        elif status == 409:
            conflict += 1
        else:
            fail += 1
        assert status in (
            200,
            201,
            409,
        ), f"Unexpected status for {CHARACTERS[idx]}: {status}"
    print(
        f"\nTotal: {len(CHARACTERS)} | Success: {success} | Conflict: {conflict} | Fail: {fail}"
    )
    print(
        f"Elapsed time: {elapsed:.2f} seconds | Requests/sec: {len(CHARACTERS)/elapsed:.2f}"
    )
