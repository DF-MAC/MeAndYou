import asyncio
import random
from typing import Callable, Any, Optional
import logging


async def exponential_backoff(
    func: Callable[..., Any],
    *args: Any,
    max_retries: int = 5,
    base_delay: float = 1,
    max_delay: float = 60,
    factor: float = 2,
    jitter: bool = True,
    **kwargs: Any
) -> Any:
    """
    Executes an asynchronous function with exponential backoff retry logic.

    Args:
    func (Callable): The asynchronous function to be executed.
    *args: Positional arguments to pass to the function.
    max_retries (int): Maximum number of retry attempts.
    base_delay (float): Initial delay between retries in seconds.
    max_delay (float): Maximum delay between retries in seconds.
    factor (float): Multiplicative factor for exponential backoff.
    jitter (bool): Whether to add randomness to the delay time.
    **kwargs: Keyword arguments to pass to the function.

    Returns:
    Any: The return value of the function if successful.

    Raises:
    Exception: The last exception encountered if all retries fail.
    """
    retries = 0
    while True:
        try:
            return await func(*args, **kwargs)
        except Exception as e:
            retries += 1
            if retries > max_retries:
                logging.error(f"Max retries reached. Last error: {str(e)}")
                raise

            delay = min(base_delay * (factor ** (retries - 1)), max_delay)
            if jitter:
                delay = random.uniform(0, delay)

            logging.warning(
                f"Retry {retries}/{max_retries} after {delay:.2f}s. Error: {str(e)}")
            await asyncio.sleep(delay)

# Example usage


async def api_call(url: str) -> dict:
    # Simulating an API call that might return a 429 status
    if random.random() < 0.7:  # 70% chance of 429 error
        raise Exception("429 Too Many Requests")
    return {"data": "Success"}


async def main():
    try:
        result = await exponential_backoff(api_call, "https://api.example.com/data")
        print("Success:", result)
    except Exception as e:
        print("Failed after all retries:", str(e))

if __name__ == "__main__":
    asyncio.run(main())
