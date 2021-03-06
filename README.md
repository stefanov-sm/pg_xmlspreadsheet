# pg_xmlspreadsheet
Export query results to Microsoft Excel format as XML spreadsheet format (SpreadsheetML).

This function is an improvement of [pg_spreadsheetml](https://github.com/stefanov-sm/pg_spreadsheetml). The prototype of the function is as follows:
```PGSQL
FUNCTION pg_xmlspreadsheet(arg_query text, arg_parameters json DEFAULT '{}') RETURNS SETOF text
```
pg_xmlspreadsheet has some differences compared to pg_spreadsheetml. Text substitution of parameters is no longer used and injection risk is checked.

__arg_query__ is parameterised.
Parameter placeholders are defined as valid uppercase identifiers with two underscores as prefix and suffix, i.e. `__FROM__`, `__TO__`, `__PATTERN__` etc.  

__NB__: Placeholders are rewritten into runtime expressions that _always_ return type `text`. This is why they may need to be explicitly cast (i.e. `__FROM__::integer, __TO__::integer` in the example below).  
  
Optional __arg_parameters__ is JSON with parameters' names/values, e.g.  
`{"from":15, "to":100015, "pattern":"%3%"}`  
Parameters' names are K&R case-insesnitive identifiers.  
  
Example:

```PGSQL
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
  	clock_timestamp() as "date and time",
  	'#<see more>##https://www.google.com/search?q='||v::text as "search Google"
  from generate_series(__FROM__::integer, __TO__::integer, 1) t(v)
  where v::text like __PATTERN__;
  $query$,
  '{"from":15, "to":100015, "pattern":"%3%"}'::json
 ) AS t(xml_line)
)
TO '/path/to/proba.xml';
```
The resulting file is zipped __proba.zip__.
