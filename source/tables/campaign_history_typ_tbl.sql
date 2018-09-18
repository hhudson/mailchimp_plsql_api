-- NOTE : The intended use of this table is not that you populate it. It merely supports the 
-- PIPELINED table output of the get_campaign_history procedure
create table campaign_history_typ_tbl (
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