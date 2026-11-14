import fakeredis

from worker import fulfill, handle_message


def test_fulfill_marks_order() -> None:
    client = fakeredis.FakeRedis(decode_responses=True)
    client.hset(
        "order:abc",
        mapping={"id": "abc", "sku": "sku-100", "qty": "1", "status": "pending"},
    )
    order_id = fulfill(client, {"order_id": "abc", "traceparent": ""})
    assert order_id == "abc"
    assert client.hget("order:abc", "status") == "fulfilled"


def test_handle_message_reads_json() -> None:
    client = fakeredis.FakeRedis(decode_responses=True)
    client.hset("order:xyz", mapping={"id": "xyz", "status": "pending"})
    assert handle_message(client, '{"order_id":"xyz","traceparent":""}') == "xyz"
    assert client.hget("order:xyz", "status") == "fulfilled"
