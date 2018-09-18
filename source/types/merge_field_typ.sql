CREATE TYPE merge_field_typ AS OBJECT (
    merge_id       INTEGER,
    tag            VARCHAR2(50),
    name           VARCHAR2(50),
    default_value  VARCHAR2(2000)
  )
/