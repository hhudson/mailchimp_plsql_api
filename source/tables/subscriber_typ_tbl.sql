-- NOTE : The intended use of this table is not that you populate it. It merely supports the 
-- PIPELINED table output of the get_list_of_subscribers procedure
CREATE TABLE subscriber_typ_tbl (
    email_address    VARCHAR2(100),
    first_name       VARCHAR2(50),
    last_name        VARCHAR2(50),
    status           varchar2(50))
/