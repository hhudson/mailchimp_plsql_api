CREATE TYPE campaign_history_typ AS OBJECT (
    campaign_id        VARCHAR2(50),
    emails_sent        INTEGER,
    send_time          DATE,
    recipient_list_id  VARCHAR2(2000),
    template_id        INTEGER,
    subject_line       VARCHAR2(100),
    from_name          VARCHAR2(200),
    opens              INTEGER,
    unique_opens       INTEGER,
    open_rate          INTEGER,
    clicks             INTEGER,
    cancel_send        VARCHAR2(1000)
  )
/