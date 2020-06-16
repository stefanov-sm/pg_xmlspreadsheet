-- Postgres server-side query to spreadsheet example

COPY
(
 SELECT xml_line FROM pg_xmlspreadsheet
 (
  $query$
  select
  	v as "value",
  	to_char(v % 4000, 'FMRN') as "mod 4000 roman",
  	v^2 as "square",
  	v^3 as "cube",
  	clock_timestamp() as "date and time"
  from generate_series(__FROM__::integer, __TO__::integer, 1) t(v)
  where v::text like __PATTERN__;
  $query$,
  json_build_object('from', 15, 'to', 100015, 'pattern', '%3%')
 ) AS t(xml_line)
)
TO '/-- path-to --/delme.xml'