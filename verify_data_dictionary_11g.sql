-- Credit goes to whoever created the queries below found on the internet
set pages 1000
set lines 200
col owner format a30
col object_name format a30
col object_type format a30
col comp_id format a20
col comp_name format a40
col version format a15
col status format a15
col dbname format a15
col ACTION_TIME format a30
col id format a10
col COMMENTS format a60
col action form a30
col description form a85
col action_date form a20

PROMPT DATABASE NAME
PROMPT =============
select sys_context('USERENV','DB_NAME') DBNAME from dual;

COLUMN y new_value sid NOPRINT
SELECT name||'_'||TO_CHAR(sysdate, 'ddmonyy_hh24mi') y FROM v$database;
set feedback off
alter system checkpoint;

alter system check datafiles;

Set Linesize 200
Set Pagesize 45
Set Desc Linenum On

Set Arraysize 1
Set Long 2000
Set Serveroutput On size 800000 ;

Set Heading  Off
Set Verify   Off

Column Var_Date new_value Var_Date noprint

Select
       To_Char(Sysdate, 'DD-MM-YYYY HH24:MI') Var_Date
  from
       v$database
;

/*
Select
       '   ******   &Var_Date   **************   Base : ' || Name || '   ************** '
  from
       v$database;

Set Heading  On

column sid        heading "Id"              format 9999
column spid       heading "Unix"            format A7
column username   heading "Utilis."         format A20
column terminal   heading "Terminal"        format A11
column program    heading "Programme"       format A27   word_wrapped

select
        s.sid, p.spid, substr(s.username,1,20) username, s.terminal, p.Program
  from
       v$session s, v$process p
 where
       s.paddr = p.addr
   and
       s.sid = (select sid from v$mystat where rownum=1)
;

Set Heading  Off
Set Termout  On

Prompt

-- Prompt ---


Set Heading  On
Set Feedback On


-- prompt
*/
Set Heading  Off
Set Verify   Off


prompt ================================================================================================
prompt ==   Oracle Instance Information
prompt ================================================================================================

prompt

SET serveroutput on
BEGIN
  Dbms_OutPut.Put_Line('--  IP Address '||Lpad(UTL_INADDR.GET_HOST_ADDRESS,14));
END;
/

column status           format a120 wrap             heading "Status"

Select status_01||'    | '||status_02 status
  From
       (Select '   Host_Name     '||Lpad(Host_Name,18) status_02 from V$Instance)
     , (Select '   Cpu_Count             '||Lpad(value,8) status_01 from V$PARAMETER where name='cpu_count' and value is not null)
Union
Select status_01||'    | '||status_02 status
  From
       (Select '   Instance_Name     '||Lpad(Instance_Name,12) Status_01 from V$Instance)
     , (Select '   Database_Status     '||Lpad(Database_Status,12) Status_02 from V$Instance)
Union
Select status_01||'    | '||status_02 status
  From
       (Select '   Startup_Time    '||To_Char(Startup_Time, 'DD-MM-YYYY HH24:MI') Status_02 from V$Instance)
     , (Select '   Status            '||Lpad(Status,12) Status_01 from V$Instance)
Union
Select status_01||'    | '||status_02 status
  From
       (Select '   Version           '||Lpad(Version,12) Status_01 from V$Instance)
     , (Select '   Instance_Role   '||Lpad(Instance_Role,16) Status_02 from V$Instance)
;

select '   Database log mode            '||log_mode "Parameter" from V$DATABASE
union
select '   Archive destination          '||value    from V$PARAMETER where (name='log_archive_dest' or name = 'log_archive_dest_1') and value is not null
;

select '   Spfile                       '||value    from V$PARAMETER where name='spfile' and value is not null
union
select '   Background Dump Dest         '||value    from V$PARAMETER where name='background_dump_dest' and value is not null
;

-- ----------------------------------------------------------------------- ---
--   Check Redo Size                                                             ---
-- ----------------------------------------------------------------------- ---

select distinct '   Redo size (Gb)    '|| Lpad(To_Char(bytes/power(1024,3)),'16') Status from v$log;

Declare
  --
  Cursor Cur_Req Is
        Select distinct object_name
      from dba_objects
      where object_name='DBA_TEMP_FILES'
        ;
  --
   Cursor Cur_SGA Is
---        select '   SGA (Gb)                '||Lpad(To_Char(Round(sum (value)/power(1024,3))),8) status_02 from v$sga;
        select '   SGA (Gb)                '||Lpad(To_Char(sum (value)/power(1024,3)),8) status_02 from v$sga;
  --
  W_Texte               Varchar2(2000);
  Curs                  Integer;
  Return_code           Integer;
  W_Temp                Varchar2(40);
  --
  X     Varchar2(100);
  Nb_Tf         Number(8);
  SGA           Varchar2(40);
  --
Begin
  --
  X := Null;
  --
  Open Cur_Req;
    Fetch Cur_Req Into X;
  Close Cur_Req;
  --
  Open Cur_SGA;
    Fetch Cur_SGA Into SGA;
  Close Cur_SGA;
  --
  If X Is Not Null Then
    --
    W_Texte :=  'Select ''Database Space (Gb)   ''||Lpad(To_Char((nb_ctl.nb * ctl_size.the_size) ';
    W_Texte :=  W_texte ||' + (rlf_size.the_size) ';
    W_Texte :=  W_texte ||' + (dtf_size.the_size) ';
    W_Texte :=  W_texte ||' + (nvl(dtft_size.the_size,0))),8) From  ';
    W_Texte :=  W_texte ||' (select count(1) nb from v$controlfile) nb_ctl ';
    W_Texte :=  W_texte ||' , (select sum(record_size)/power(1024,3) the_size from V$CONTROLFILE_RECORD_SECTION) ctl_size ';
    W_Texte :=  W_texte ||' , (select sum(bytes)/power(1024,3) the_size from v$log) rlf_size ';
    W_Texte :=  W_texte ||' , (select sum(bytes)/power(1024,3) the_size from dba_data_files) dtf_size ';
    W_Texte :=  W_texte ||' , (select sum(bytes)/power(1024,3) the_size from dba_temp_files) dtft_size';
    --
  Else
    --
    W_Texte :=  'Select ''Database Space (Gb)   ''||Lpad(To_Char((nb_ctl.nb * ctl_size.the_size) ';
    W_Texte :=  W_texte ||' + (rlf_size.the_size) ';
    W_Texte :=  W_texte ||' + (dtf_size.the_size) ';
    W_Texte :=  W_texte ||' + (nvl(dtft_size.the_size,0))),8) From  ';
    W_Texte :=  W_texte ||' (select count(1) nb from v$controlfile) nb_ctl ';
    W_Texte :=  W_texte ||' , (select sum(record_size)/power(1024,3) the_size from V$CONTROLFILE_RECORD_SECTION) ctl_size ';
    W_Texte :=  W_texte ||' , (select sum(bytes)/power(1024,3) the_size from v$log) rlf_size ';
    W_Texte :=  W_texte ||' , (select sum(bytes)/power(1024,3) the_size from dba_data_files) dtf_size ';
    --
  End If;
  --
  Curs := Dbms_Sql.Open_Cursor;
  --
  Dbms_Sql.Parse(Curs, W_texte, Dbms_Sql.Native);
  Dbms_Sql.Define_Column(Curs, 1, W_Temp, 40);
  --
  Return_Code := Dbms_Sql.Execute(Curs);
  --
  IF dbms_sql.FETCH_ROWS(Curs)>0 THEN
    Dbms_Sql.Column_Value(Curs, 1, W_Temp);
  End If;
  --
  Dbms_OutPut.Put_Line('-- '||W_Temp||'    | '||SGA||' --');
  --
  Dbms_Sql.Close_Cursor(Curs);
  --
End;
/

Declare
  --
  Cursor Cur_Req Is
        Select distinct object_name
      from dba_objects
      where object_name='DBA_TEMP_FILES'
        ;
  --
  Cursor Cur_Df Is
        Select Count(*)
      From dba_data_files
        ;
  --
  W_Texte               Varchar2(2000);
  Curs                  Integer;
  Return_code           Integer;
  W_Temp                Varchar2(20);
  --
  X     Varchar2(100);
  Nb_Tf         Number(8);
  Nb_Df         Number(8);
  --
Begin
  --
  X := Null;
  --
  Open Cur_Req;
    Fetch Cur_Req Into X;
  Close Cur_Req;
  --
  Open Cur_Df;
    Fetch Cur_Df Into Nb_Df;
  Close Cur_Df;
  --
  If X Is Not Null Then
    --
    W_Texte :=  'Select To_Char(Count(*)) From dba_temp_files';
    --
    Curs := Dbms_Sql.Open_Cursor;
    --
    Dbms_Sql.Parse(Curs, W_texte, Dbms_Sql.Native);
    Dbms_Sql.Define_Column(Curs, 1, W_Temp, 20);
    --
    Return_Code := Dbms_Sql.Execute(Curs);
    --
    IF dbms_sql.FETCH_ROWS(Curs)>0 THEN
      Dbms_Sql.Column_Value(Curs, 1, W_Temp);
    End If;
    --
    Dbms_OutPut.Put_Line('-- Nb. Datafiles            '||Lpad(To_Char(Nb_Df),5)||'    |    Nb. Tempfiles              '||Lpad(W_Temp,5)||' --' );
    --
    Dbms_Sql.Close_Cursor(Curs);
    --
  Else
    Dbms_OutPut.Put_Line('-- Nb. Datafiles            '||Lpad(To_Char(Nb_Df),5));
  End If;
  --
End;
/
prompt
prompt
Set Heading on
Set Verify   On
set feedback on

PROMPT DBA_REGISTRY CONTENTS
PROMPT ================================================================
select comp_id,comp_name,version,status from dba_registry;
PROMPT LIST APPLIED PATCHES
PROMPT =======================
select substr(action_time,1,30) action_time,substr(id,1,10) id,substr(action,1,10) action,substr(version,1,8) version,substr(BUNDLE_SERIES,1,6) bundle,substr(comments,1,20) comments
from registry$history;
PROMPT LIST APPLIED SQL PATCHES
PROMPT =======================
select comments, action, to_char(action_time,'DD/MM/RR HH24:MI:SS') action_date, version
from registry$history
order by action_date;
PROMPT COUNT OF INVALID OBJECTS
PROMPT ========================
select count(*) from dba_objects where status='INVALID' and owner in ('SYS','SYSTEM');
PROMPT INVALID OBJECTS GROUPED BY OBJECT TYPE AND OWNER
PROMPT ================================================
select owner,object_type,count(*) from dba_objects where status='INVALID' and owner in ('SYS','SYSTEM') group by owner,object_type;
PROMPT LIST OF SYS INVALID OBJECTS
PROMPT =======================
select owner,object_name,object_type from dba_objects where status='INVALID' and owner in ('SYS','SYSTEM');
