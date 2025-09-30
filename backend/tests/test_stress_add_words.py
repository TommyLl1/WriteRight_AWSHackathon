import httpx
import asyncio
import pytest
import time

# List of characters to test
CHARACTERS = [
    "氣",
    "陰",
    "陽",
    "星",
    "辰",
    "霧",
    "露",
    "霜",
    "父",
    "母",
    "夫",
    "妻",
    "爺",
    "奶",
    "伯",
    "叔",
    "眉",
    "髮",
    "膚",
    "齒",
    "頸",
    "肩",
    "膝",
    "肘",
    "岩",
    "礦",
    "島",
    "岸",
    "浪",
    "潮",
    "灣",
    "洋",
    "蓮",
    "菊",
    "蘭",
    "梅",
    "杏",
    "桃",
    "梨",
    "莓",
    "蟬",
    "蠶",
    "蛛",
    "蠍",
    "蟋",
    "蟀",
    "蚱",
    "蜢",
    "鯨",
    "鯊",
    "鰻",
    "鱉",
    "鱷",
    "鰭",
    "鮭",
    "鱒",
    "犀",
    "豹",
    "狸",
    "貂",
    "獺",
    "獾",
    "鼬",
    "鼴",
    "廟",
    "寺",
    "庵",
    "塔",
    "壇",
    "殿",
    "廊",
    "亭",
    "枕",
    "毯",
    "扇",
    "傘",
    "壺",
    "盆",
    "缸",
    "甕",
    "鈔",
    "幣",
    "鈿",
    "鑽",
    "瑪",
    "瑙",
    "琥",
    "珀",
    "笛",
    "簫",
    "瑟",
    "箏",
    "磬",
    "缽",
    "鑼",
    "鈸",
    "韻",
    "律",
    "譜",
    "調",
    "奏",
    "拍",
    "節",
    "腔",
    "靈",
    "魂",
    "魄",
    "魅",
    "魍",
    "魎",
    "巫",
    "祀",
    "澀",
    "膩",
    "脆",
    "酥",
    "腐",
    "霉",
    "腥",
    "臊",
    "銳",
    "鈍",
    "滑",
    "糙",
    "黏",
    "稠",
    "稀",
    "疏",
    "漲",
    "跌",
    "贏",
    "虧",
    "貸",
    "債",
    "贈",
    "賠",
    "娶",
    "嫁",
    "婚",
    "姻",
    "聘",
    "媒",
    "妗",
    "娣",
    "謎",
    "諺",
    "謊",
    "諷",
    "誦",
    "詠",
    "讖",
    "譏",
    "孕",
    "育",
    "胎",
    "胞",
    "乳",
    "哺",
    "孺",
    "嬰",
    "盜",
    "賊",
    "匪",
    "寇",
    "囚",
    "牢",
    "獄",
    "刑",
    "禪",
    "齋",
    "戒",
    "誦",
    "懺",
    "悔",
    "虔",
    "誠",
    "錦",
    "繡",
    "緞",
    "綢",
    "紗",
    "縷",
    "絨",
    "綾",
    "閨",
    "閣",
    "閭",
    "巷",
    "衖",
    "衕",
    "墅",
    "邸",
]

API_URL = "http://localhost:8000/user/wrong-words"  # Updated endpoint for wrong words
CONCURRENCY_LIMIT = 30  # Limit concurrent requests


async def add_wrong_word(client, word, user_id, semaphore):
    async with semaphore:
        payload = {"user_id": user_id, "word": word}
        response = await client.post(API_URL, json=payload)
        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type:
            resp_data = response.json()
        else:
            resp_data = response.text
        return response.status_code, resp_data


@pytest.mark.asyncio
async def test_add_wrong_words_volume_stress(wrong_words_test_user_id):
    pytest.skip(
        "Skipping test_add_wrong_words_volume_stress as it is not suitable for CI/CD environment"
    )
    semaphore = asyncio.Semaphore(CONCURRENCY_LIMIT)
    async with httpx.AsyncClient(timeout=10) as client:
        start_time = time.perf_counter()
        tasks = [
            add_wrong_word(client, char, wrong_words_test_user_id, semaphore)
            for char in CHARACTERS
        ]
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
                400,  # Assuming 400 is a valid failure status for this test, cuz input is not validated
                409,
            ), f"Unexpected status for {CHARACTERS[idx]}: {status}"
        print(
            f"\nTotal: {len(CHARACTERS)} | Success: {success} | Conflict: {conflict} | Fail: {fail}"
        )
        print(
            f"Elapsed time: {elapsed:.2f} seconds | Requests/sec: {len(CHARACTERS)/elapsed:.2f}"
        )
