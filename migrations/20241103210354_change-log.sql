
CREATE OR REPLACE FUNCTION private.t1000_change_log()
RETURNS TRIGGER AS $$
DECLARE
    old_row RECORD;
    new_row RECORD;
    column_name TEXT;
    json_output JSONB;
    column_value TEXT;
    is_different BOOLEAN;
    old_value TEXT;
    new_value TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        new_row := NEW;
        FOR column_name IN SELECT x.column_name FROM information_schema.columns x WHERE x.table_name = TG_TABLE_NAME LOOP
            IF new_row.* IS NOT NULL THEN
                EXECUTE format('SELECT ($1).%I::TEXT', column_name) INTO STRICT column_value USING new_row;
                IF column_value IS NOT NULL THEN
                    json_output := json_build_object(
                        'table', TG_TABLE_NAME,
                        'schema', TG_TABLE_SCHEMA,
                        'operation', TG_OP,
                        'column', column_name,
                        'new_value', column_value
                    );
                    RAISE NOTICE '%', json_output;
                END IF;
            END IF;
        END LOOP;
    ELSIF TG_OP = 'UPDATE' THEN
        old_row := OLD;
        new_row := NEW;
        FOR column_name IN SELECT x.column_name FROM information_schema.columns x WHERE x.table_name = TG_TABLE_NAME LOOP
            EXECUTE format('SELECT ($1).%I::TEXT <> ($2).%I::TEXT OR (($1).%I IS NULL) <> (($2).%I IS NULL)',
                           column_name, column_name, column_name, column_name)
            INTO STRICT is_different USING old_row, new_row;

            IF is_different THEN
                EXECUTE format('SELECT ($1).%I::TEXT, ($2).%I::TEXT', column_name, column_name)
                INTO STRICT old_value, new_value USING old_row, new_row;
                json_output := json_build_object(
                    'table', TG_TABLE_NAME,
                    'schema', TG_TABLE_SCHEMA,
                    'operation', TG_OP,
                    'column', column_name,
                    'old_value', old_value,
                    'new_value', new_value
                );
                RAISE NOTICE '%', json_output;
            END IF;
        END LOOP;
    ELSIF TG_OP = 'DELETE' THEN
        old_row := OLD;
        FOR column_name IN SELECT x.column_name FROM information_schema.columns x WHERE x.table_name = TG_TABLE_NAME LOOP
            IF old_row.* IS NOT NULL THEN
                EXECUTE format('SELECT ($1).%I::TEXT', column_name) INTO STRICT column_value USING old_row;
                IF column_value IS NOT NULL THEN
                    json_output := json_build_object(
                        'table', TG_TABLE_NAME,
                        'schema', TG_TABLE_SCHEMA,
                        'operation', TG_OP,
                        'column', column_name,
                        'old_value', column_value
                    );
                    RAISE NOTICE '%', json_output;
                END IF;
            END IF;
        END LOOP;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION private.stk_table_trigger_create()
RETURNS void AS $$
DECLARE
    my_table_record RECORD;
    my_trigger_name TEXT;
BEGIN
    FOR my_table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'private'
          AND table_type = 'BASE TABLE'
    LOOP
        -- Derive the trigger name from the table name
        my_trigger_name := my_table_record.table_name || '_tgr_t1000';

        -- Check if the trigger already exists
        IF NOT EXISTS (
            SELECT 1
            FROM information_schema.triggers
            WHERE trigger_schema = 'private'
              AND event_object_table = my_table_record.table_name
              AND trigger_name = my_trigger_name
        ) THEN
            -- Create the trigger if it doesn't exist
            EXECUTE format(
                'CREATE TRIGGER %I
                 AFTER INSERT OR UPDATE OR DELETE ON private.%I
                 FOR EACH ROW EXECUTE FUNCTION private.t1000_change_log()',
                my_trigger_name,
                my_table_record.table_name
            );

            RAISE NOTICE 'Created trigger % on table private.%', my_trigger_name, my_table_record.table_name;
        ELSE
            --RAISE NOTICE 'Trigger % already exists on table private.%', my_trigger_name, my_table_record.table_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;


select private.stk_table_trigger_create();

---- manual test
-- create table private.delme_trigger (name text, description text);
-- select private.stk_table_trigger_create();
-- insert into private.delme_trigger values ('name1','desc1');
-- update private.delme_trigger set description = 'desc1 - updated';
-- delete from private.delme_trigger;

