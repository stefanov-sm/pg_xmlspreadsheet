-- Postgres server-side query to spreadsheet 

CREATE OR REPLACE FUNCTION public.pg_xmlspreadsheet(arg_query text, arg_parameters json DEFAULT '{}'::json)
RETURNS SETOF text LANGUAGE plpgsql AS 
$function$

DECLARE

WORKBOOK_HEADER constant text[] := array[
'<?xml version="1.0" encoding="utf8"?>',
'<?mso-application progid="Excel.Sheet"?>',
'<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
'  <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">',
'   <Subject>Postgres spreadsheet export</Subject>',
'   <Author>pg_xmlspreadsheet</Author>',
'   <Company>https://github.com/stefanov-sm/pg_xmlspreadsheet</Company>',
'  </DocumentProperties>',
'  <Styles>',
'   <Style ss:ID="Default" ss:Name="Normal"><Font ss:FontName="Arial" ss:Size="10" ss:Color="#000000"/></Style>',
'   <Style ss:ID="Date"><NumberFormat ss:Format="Short Date"/></Style>',
'   <Style ss:ID="DateTime"><NumberFormat ss:Format="yyyy-mm-dd hh:mm:ss"/></Style>',
'   <Style ss:ID="Header">',
'    <Borders>',
'     <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>',
'     <Border ss:Position="Top"    ss:LineStyle="Continuous" ss:Weight="1"/>',
'     <Border ss:Position="Left"   ss:LineStyle="Continuous" ss:Weight="1"/>',
'     <Border ss:Position="Right"  ss:LineStyle="Continuous" ss:Weight="1"/>',
'    </Borders>',
'    <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>',
'   </Style>',
'  </Styles>',
'  <Worksheet ss:Name="Sheet">',
'  <Table>'
];

WORKBOOK_FOOTER constant text[] := array[
'</Table>',
'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">',
'   <FreezePanes/><FrozenNoSplit/><SplitHorizontal>1</SplitHorizontal>',
'   <TopRowBottomPane>1</TopRowBottomPane><ActivePane>2</ActivePane>',
'  </WorksheetOptions>',
'  </Worksheet>',
'</Workbook>'
];

TITLE_ITEM    constant text := '    <Cell ss:StyleID="Header"><Data ss:Type="String">__VALUE__</Data></Cell>';
DATE_ITEM     constant text := '    <Cell ss:StyleID="Date"><Data ss:Type="DateTime">__VALUE__</Data></Cell>';
DTIME_ITEM    constant text := '    <Cell ss:StyleID="DateTime"><Data ss:Type="DateTime">__VALUE__</Data></Cell>';
TEXT_ITEM     constant text := '    <Cell><Data ss:Type="String">__VALUE__</Data></Cell>';
NUMBER_ITEM   constant text := '    <Cell><Data ss:Type="Number">__VALUE__</Data></Cell>';
BOOL_ITEM     constant text := '    <Cell><Data ss:Type="Boolean">__VALUE__</Data></Cell>';
EMPTY_ITEM    constant text := '    <Cell></Cell>';

COLUMN_ITEM   constant text := '   <Column ss:AutoFitWidth="0" ss:Width="__VALUE__"/>';
BEGIN_ROW     constant text := '   <Row>';
END_ROW       constant text := '   </Row>';
SR_TOKEN      constant text := '__VALUE__';

AVG_CHARWIDTH constant integer := 5.5;
MIN_FLDWIDTH  constant integer := 40;
TS_CHOP_SIZE  constant integer := 19;

r record;
jr json;
v_key text;
v_value text;
column_types text[];
running_line text;
running_column integer;
cold boolean := true;

BEGIN

foreach v_value in array WORKBOOK_HEADER loop
  	return next v_value;
  end loop;

  -- Rewrite the input qwery. Replace parameter placeholders with json attribute expressions  
  for v_key in select "key" from json_each_text(arg_parameters) loop
    arg_query := replace(arg_query, '__'||upper(v_key)||'__', '($1->>'''||v_key||''')');
  end loop;

  -- Now it is possible to run injection-safe 'execute using' 
  for r in execute arg_query using arg_parameters loop

    jr := to_json(r);
    if cold then
      column_types := (select array_agg(json_typeofx("value")) from json_each(jr) jt);
      for v_key in select "key" from json_each_text(jr) jt loop
        running_line := replace(COLUMN_ITEM, SR_TOKEN, greatest(length(v_key) * AVG_CHARWIDTH, MIN_FLDWIDTH)::text);
        return next running_line;
      end loop;
      return next BEGIN_ROW;
      for v_key in select "key" from json_each_text(jr) jt loop
        running_line := replace(TITLE_ITEM, SR_TOKEN, xml_escape(v_key));
        return next running_line;
      end loop;
      return next END_ROW;
      cold := false;
    end if;

    return next BEGIN_ROW;
    running_column := 1;

    for v_key, v_value in select "key", "value" from json_each_text(jr) jt loop
      if v_value is null then
        running_line := EMPTY_ITEM;
      else
        if column_types[running_column] = 'null' then
          column_types[running_column] := json_typeofx(jr -> v_key);
        end if;
        case column_types[running_column]
          when 'string'   then running_line := replace(TEXT_ITEM,   SR_TOKEN, xml_escape(v_value));
          when 'number'   then running_line := replace(NUMBER_ITEM, SR_TOKEN, v_value);
          when 'boolean'  then running_line := replace(BOOL_ITEM,   SR_TOKEN, v_value::boolean::int::text);
          when 'date'     then running_line := replace(DATE_ITEM,   SR_TOKEN, v_value);
          when 'datetime' then running_line := replace(DTIME_ITEM,  SR_TOKEN, left(v_value, TS_CHOP_SIZE));
          else                 running_line := replace(TEXT_ITEM,   SR_TOKEN, xml_escape(v_value));
        end case;
      end if;
      running_column := running_column + 1;
      return next running_line;
    end loop;
    return next END_ROW;
  end loop;

  foreach v_value in array WORKBOOK_FOOTER loop
  	return next v_value;
  end loop;

END;
$function$;
