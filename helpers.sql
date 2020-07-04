----------------------------------------------------
-- pg_xmlspreadsheet helpers, S. Stefanov, June-2020
----------------------------------------------------

create or replace function xml_escape(s text)
returns text language sql immutable strict as
$$
  select replace(replace(replace(s, '&', '&amp;'), '>', '&gt;'), '<', '&lt;');
$$;

create or replace function public.json_typeofx(j json)
returns text language sql immutable strict as
$$
select
  case
    when json_typeof(j) = 'string' then case 
      when j::text ~ '^"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?' then 'datetime'
      when j::text ~ '^"\d{4}-\d\d-\d\d' then 'date'
      when j::text ~ '^"#.+##.+' then 'href'
      else 'string' 
    end
    else json_typeof(j)
  end;
$$;

create or replace function public.dynsql_safe(arg_query text, arg_parameters json)
returns text language plpgsql immutable strict as
$$
declare
	running_key text;
begin
	-- Rewrite the query. Convert __MACRO__ placeholders into json attribute text expressions
	for running_key in select "key" from json_each_text(arg_parameters) loop
		arg_query := replace(arg_query, '__' || upper(running_key) || '__', '($1->>''' || running_key || ''')');
	end loop;
	return arg_query;
end;
$$;
