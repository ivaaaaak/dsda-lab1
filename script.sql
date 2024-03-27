DO $$
DECLARE
	schema_name text = 'public';
	table_name text = 'child';
	table_oid int;
	col RECORD;

BEGIN
	SELECT oid into table_oid FROM pg_class WHERE relname=table_name AND relnamespace=schema_name::regnamespace AND reltype != 0;
	
	IF table_oid is null THEN
		RAISE EXCEPTION 'Таблица "%" не найдена в схеме "%"', table_name, schema_name;
	END IF;
	
	RAISE NOTICE ' ';
    	RAISE NOTICE 'Таблица: %', table_name;
    	RAISE NOTICE ' ';
    	RAISE NOTICE 'No.  Имя столбца      Атрибуты';
    	RAISE NOTICE '---  --------------   -------------------------------------------------';
	
	FOR col IN 
	
	SELECT attnum, attname, attnotnull, atttypmod, typname, description, conname, contype, pg_get_constraintdef(constr.oid, true) AS constraint_definition 
	FROM pg_attribute attr
		
	JOIN pg_type typ on attr.atttypid = typ.oid 
	LEFT JOIN pg_constraint constr ON attr.attrelid = constr.conrelid AND attr.attnum = ANY(constr.conkey)
	LEFT JOIN pg_description des on des.objoid = table_oid and des.objsubid = attr.attnum
		
	WHERE attrelid=table_oid and attnum > 0
	ORDER BY attnum
	
		LOOP
			RAISE NOTICE '% % Type    :  % %', RPAD(col.attnum::text, 5, ' '), RPAD(col.attname, 16, ' '),
			CASE
				WHEN col.atttypmod != -1 THEN concat(col.typname, '(', col.atttypmod, ')')
			 	ELSE col.typname
		     	END,
		     	CASE
				WHEN col.attnotnull THEN 'NOT_NULL' ELSE '' 
			END;
			
			IF col.conname is not null and col.contype = 'c' THEN
				RAISE NOTICE '% CONSTR  :  "%"', RPAD('⠀', 22, ' '), concat(col.conname, ' ', col.constraint_definition);
			END IF;

			IF col.description is not null THEN
				RAISE NOTICE '% Comment  :  "%"', RPAD('⠀', 22, ' '), col.description;
			END IF;
			
            	RAISE NOTICE ' ';
		END LOOP;
END;
$$;
