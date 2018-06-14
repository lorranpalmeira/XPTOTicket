set head off
set pagesize 0
set feed off

purge recyclebin
/


spool c:\temp\xdropusr.sql

select 'drop '||rtrim(object_type) || ' ' || rtrim(object_name)||
' cascade constraints;' from user_objects where object_type = 'TABLE';

select 'drop '||rtrim(object_type)||' '||rtrim(object_name) || ';'
  from user_objects where object_type not in ('TABLE','INDEX','TRIGGER');

select 'drop public synonym '||rtrim(synonym_name)||';' from all_synonyms
where table_owner = (select user from dual);

spool off
set feed on
set head on
set pagesize 25
@c:\temp\xdropusr.sql
/
purge recyclebin
/
