CREATE TYPE subscriber_typ AS OBJECT (
    email_address    VARCHAR2(100),
    first_name       VARCHAR2(50),
    last_name        VARCHAR2(50),
    status           varchar2(50)
  )
/