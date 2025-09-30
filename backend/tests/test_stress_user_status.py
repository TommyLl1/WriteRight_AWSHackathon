import httpx
import asyncio
import pytest
import time

API_URL = "https://writeright-1.eastasia.cloudapp.azure.com/api-9687094a/user/status"
CONCURRENCY_LIMIT = 20  # Adjust as needed
ROUNDS = 100  # Adjust the number of rounds as needed

# Example: Replace with actual test user IDs or parametrize as needed
USER_IDS = [
    # "b2977f0b-b464-4be3-9057-984e7ac4c9a9",
    # "4767db57-8ae6-484d-8f9f-8ad977fb3157",
    # "033610f9-5741-4341-ae4d-198dd3d0a9d4",
]


async def fetch_user_status(client, user_id, semaphore):
    async with semaphore:
        params = {"user_id": user_id}
        response = await client.get(API_URL, params=params)
        content_type = response.headers.get("content-type", "")
        if "application/json" in content_type:
            resp_data = response.json()
        else:
            resp_data = response.text
        return response.status_code, resp_data


@pytest.mark.asyncio
async def test_user_status_stress():
    global USER_IDS
    if not USER_IDS:
        pytest.skip("No test user IDs provided for stress test.")
    USER_IDS *= ROUNDS
    semaphore = asyncio.Semaphore(CONCURRENCY_LIMIT)
    async with httpx.AsyncClient(timeout=20) as client:
        start_time = time.perf_counter()
        tasks = [fetch_user_status(client, user_id, semaphore) for user_id in USER_IDS]
        results = await asyncio.gather(*tasks)
        elapsed = time.perf_counter() - start_time
        success, fail, not_found = 0, 0, 0
        for idx, (status, resp) in enumerate(results):
            print(f"{USER_IDS[idx]}: status={status}, response={resp}")
            if status == 200:
                success += 1
            elif status == 404:
                not_found += 1
            else:
                fail += 1
            assert status in (
                200,
                404,
            ), f"Unexpected status for {USER_IDS[idx]}: {status}"
        print(
            f"\nTotal: {len(USER_IDS)} | Success: {success} | Not found: {not_found} | Fail: {fail}"
        )
        print(
            f"Elapsed time: {elapsed:.2f} seconds | Requests/sec: {len(USER_IDS)/elapsed if USER_IDS else 0:.2f}"
        )
