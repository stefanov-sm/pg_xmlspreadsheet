# pg_xmlspreadsheet
Export query results to Excel as XML spreadsheet format (SpreadsheetML)

This function is an improvement of [pg_spreadsheetml](https://github.com/stefanov-sm/pg_spreadsheetml)

```PGSQL
FUNCTION pg_xmlspreadsheet(arg_query text, arg_parameters json DEFAULT '{}'::json)
 RETURNS SETOF text
 LANGUAGE plpgsql
```
__arg_query__ is parameterised by plain text susbtitution (macro expansion).  
Macro parameter placeholders are defined as valid uppercase identifiers with two underscores as prefix and suffix, i.e. `__NUMBER_OF_DAYS__`, `__COST__`, etc. See the [example](https://github.com/stefanov-sm/pg_spreadsheetml/tree/master/example) SQL-only and PHP CLI scripts.

Optional __arg_parameters__ is JSON with parameters' names/values, i.e. `{"number_of_days":"7 days", "cost":15.00}`. Parameters' names are K&R case-insesnitive identifiers.

__Note:__ pg_spreadsheetml is __injection prone__ and therefore it must be declared as a security definer owned by a limited user.


__Note:__ The example runs against the popular [DVD rental](https://www.postgresqltutorial.com/postgresql-sample-database/) sample database.
