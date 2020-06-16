---------------------------------------------------
-- pg_xmlspreadsheet helpers, S. Stefanov, Feb-2020
---------------------------------------------------

create or replace function xml_escape(s text)
returns text language sql immutable strict as
$$
  select replace(replace(replace(s, '&', '&amp;'), '>', '&gt;'), '<', '&lt;');
$$;

create or replace function json_typeofx(j json)
returns text language sql immutable as
$$
  select
    case
      when json_typeof(j) = 'string' then 
        case 
          when j::text ~ '^"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?' then 'datetime'
          when j::text ~ '^"\d{4}-\d\d-\d\d' then 'date'
          else 'string' 
        end
      else json_typeof(j)
    end;
$$;