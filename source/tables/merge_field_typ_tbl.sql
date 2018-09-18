-- NOTE : The intended use of this table is not that you populate it. It merely supports the 
-- PIPELINED table output of the get_list_of_merge_fields procedure
create table merge_field_typ_tbl (
    merge_id       INTEGER,
    tag            VARCHAR2(50),
    name           VARCHAR2(50),
    default_value  VARCHAR2(2000)
  )
/