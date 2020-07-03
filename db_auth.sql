SET TERM #;
EXECUTE BLOCK
AS
  DECLARE VARIABLE tablename VARCHAR(32);
BEGIN
  FOR SELECT rdb$relation_name
  FROM rdb$relations
  WHERE rdb$view_blr IS NULL
  AND (rdb$system_flag IS NULL OR rdb$system_flag = 0)
  INTO :tablename DO
  BEGIN
    EXECUTE STATEMENT ('GRANT INSERT, SELECT ON TABLE ' || :tablename || ' TO PUBLIC');
    EXECUTE STATEMENT ('GRANT DELETE, INSERT, UPDATE, SELECT, REFERENCES ON TABLE ' || :tablename || ' TO replicant');
  END
END#
SET TERM ;# 