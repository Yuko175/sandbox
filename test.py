def func_b():
    publish_article(False)


def publish_article(should_update_timestamp=True):
    check_box_value = get_checkbox_value_from_db()
    is_checked_update_timestamp = check_box_value.update_timestamp
    if should_update_timestamp and is_checked_update_timestamp:
        update_timestamp()
