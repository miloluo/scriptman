create or replace function f_get_from_dump
(
p_dump in varchar2,
p_type in varchar2
)
return varchar2 as
v_length_str varchar2(10);
v_length number default 7;
v_dump_rowid varchar2(30000);

v_date_str varchar2(100);
type t_date is table of number index by binary_integer;
v_date t_date;

function f_add_prefix_zero(p_str in varchar2, p_positioin in number) return varchar2
as 
v_str varchar2(30000) := p_str;
v_position number := p_position;
v_str_part varchar2(30000);
begin
while(v_position != 0) loop
    v_str_part := substr(v_str,1,v_position-1);
    v_str := substr(v_str,v_position+1);
    
    if v_position = 2 then
        v_return := v_return || '0' || v_str_part;
    elsif v_position = 3 then
        v_return := v_return || v_str_part;
    else
        raise_application_error(-20002,'DUMP ERROR CHECK THE INPUT ROWID');
    end if;
    
    v_position := instr(v_str,',');
    
    end loop;
    return replace(v_return,',');
    
end f_add_prefix_zero;


begin 
    if substr(p_dump,1,3) = 'Typ' then
        v_dump_rowid := substr(p_dump, instr(p_dump,':')+2);
    else 
        v_dump_rowid := p_dump;
    end if;
    
    if p_type = 'VARCHAR2' or p_type='CHAR' then
        v_dump_rowid := f_add_prefix_zero(v_dump_rowid || ',',instr(v_dump_rowid,','));
        return(utl_raw.cast_to_varchar2(v_dump_rowid));
    elsif p_type='NVARCHAR2' or p_type='NCHAR' then
        v_dump_rowid := f_add_prefix_zero(v_dump_rowid || ',',instr(v_dump_rowid,','));
        return(utl_raw.cast_to_nvarchar2(v_dump_rowid));
     elsif p_type='NUMBER' then
        v_dump_rowid := f_add_prefix_zero(v_dump_rowid || ',',instr(v_dump_rowid,','));
        return(to_char(utl_raw.cast_to_number(v_dump_rowid)));
     elsif p_type='DATE' then
        v_dump_rowid := ','||v_dump_rowid||',';
        for i in 1..7 loop
            v_date(i) := to_number(substr(v_dump_rowid,instr(v_dump_rowid,',',1,i)+1, instr(v_dump_rowid,',',1, i+1) - instr(v_dump_rowid,',',1,i)-1),'XXX');
        end loop;
        
        v_date(1) := v_date(1) - 100;
        v_date(2) := v_date(2) - 100;
        
        if (v_date(1) < 0) or (v_date(2) < 0) then
            v_date_str := '-' || ltrim(to_char(abs(v_date(1)),'00')) || ltriim(to_char(abs(v_date(2)),'00'));
        else
            v_date_str :=ltrim(to_char(abs(v_date(1)),'00')) || ltrim(to_char(abs(v_date(2),'00'));
