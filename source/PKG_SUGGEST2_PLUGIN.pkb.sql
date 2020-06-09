
CREATE OR REPLACE PACKAGE BODY "PKG_SUGGEST2_PLUGIN" AS

    FUNCTION render_dynamic_action (
        p_dynamic_action  IN  apex_plugin.t_dynamic_action,
        p_plugin          IN  apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_render_result IS
    --
    -- plugin attributes

        l_result             apex_plugin.t_dynamic_action_render_result;
        l_attr_page_item     p_dynamic_action.attribute_01%TYPE := p_dynamic_action.attribute_01;
        l_attr_title         p_dynamic_action.attribute_02%TYPE := p_dynamic_action.attribute_02;
        l_attr_lov           p_dynamic_action.attribute_03%TYPE := p_dynamic_action.attribute_03;
        l_attr_removable     p_dynamic_action.attribute_05%TYPE := p_dynamic_action.attribute_05;
        l_attr_rapid         p_dynamic_action.attribute_08%TYPE := p_dynamic_action.attribute_08;
        l_attr_icon          p_dynamic_action.attribute_09%TYPE := p_dynamic_action.attribute_09;
        l_attr_custom_html   p_dynamic_action.attribute_10%TYPE := p_dynamic_action.attribute_10;
        l_column_value_list  apex_plugin_util.t_column_value_list;
        l_has_lov            VARCHAR2(1);
        
    BEGIN
    -- Debug
        IF apex_application.g_debug THEN
            apex_plugin_util.debug_dynamic_action(p_plugin => p_plugin, p_dynamic_action => p_dynamic_action);
        END IF;
        
        IF l_attr_lov IS NOT NULL THEN      
            l_has_lov := 'Y';
        ELSE  
            l_has_lov := 'N';   
        END IF;
        

        l_result.javascript_function := 'mporan_suggest2.loadSuggestions';
        l_result.ajax_identifier := apex_plugin.get_ajax_identifier;
        l_result.attribute_01 := l_attr_page_item;
        l_result.attribute_02 := l_attr_title;
        l_result.attribute_03 := l_has_lov;
        l_result.attribute_05 := l_attr_removable;
        l_result.attribute_08 := l_attr_rapid;
        l_result.attribute_09 := l_attr_icon;
        l_result.attribute_10 := l_attr_custom_html;
        RETURN l_result;
    END render_dynamic_action;

    FUNCTION da_ajax (
        p_dynamic_action  IN  apex_plugin.t_dynamic_action,
        p_plugin          IN  apex_plugin.t_plugin
    ) RETURN apex_plugin.t_dynamic_action_ajax_result IS

        l_result                 apex_plugin.t_dynamic_action_ajax_result;
        l_buffer                 VARCHAR2(32767);
        l_column_value_list      apex_plugin_util.t_column_value_list;
        l_attr_page_item         p_dynamic_action.attribute_01%TYPE := p_dynamic_action.attribute_01;
        l_attr_lov               p_dynamic_action.attribute_03%TYPE := p_dynamic_action.attribute_03;
        l_attr_limit             p_dynamic_action.attribute_04%TYPE := p_dynamic_action.attribute_04;
        l_attr_remove_1_plsql    p_dynamic_action.attribute_06%TYPE := p_dynamic_action.attribute_06;
        l_attr_remove_all_plsql  p_dynamic_action.attribute_07%TYPE := p_dynamic_action.attribute_07;
        l_plsql                  VARCHAR2(32767);
    BEGIN
        IF l_attr_limit IS NULL THEN
            l_attr_limit := 8;
        ELSIF l_attr_limit > 20 THEN
            l_attr_limit := 20;
        END IF;

        apex_debug.message('suggest2 ajax function');
        IF apex_application.g_x01 = 'DRAW' THEN
            apex_debug.message('suggest2 ajax function DRAW');
            l_attr_lov := replace(l_attr_lov, '@PAGE_ITEM@', l_attr_page_item);
            l_column_value_list := apex_plugin_util.get_data(p_sql_statement => l_attr_lov, p_min_columns => 2, p_max_columns => 50,
            p_component_name => 'document', p_max_rows => l_attr_limit);

            apex_json.initialize_clob_output;
            apex_json.open_array;
            FOR row_idx IN 1..l_column_value_list(1).count LOOP
                apex_json.open_array;
                FOR column_idx IN 1..l_column_value_list.count LOOP
                    apex_json.write(apex_escape.html(l_column_value_list(column_idx)(row_idx)));
                END LOOP;

                apex_json.close_array;
            END LOOP;

            apex_json.close_array;
            sys.htp.p(apex_json.get_clob_output);
            apex_json.free_output;
        ELSIF apex_application.g_x01 = 'DELETE' THEN
            l_plsql := l_attr_remove_1_plsql;
            l_plsql := replace(l_plsql, '@ID@', ''
                                                || apex_application.g_x02
                                                || '');

            l_plsql := replace(l_plsql, '@PAGE_ITEM@', l_attr_page_item);
            apex_debug.message('suggest2 ajax function execute_plsql_code: ' || l_plsql);
            apex_plugin_util.execute_plsql_code(p_plsql_code => l_plsql);
        ELSIF apex_application.g_x01 = 'DELETE_ALL' THEN
            l_plsql := replace(l_attr_remove_all_plsql, '@PAGE_ITEM@', l_attr_page_item);
            apex_debug.message('suggest2 ajax function execute_plsql_code: ' || l_plsql);
            apex_plugin_util.execute_plsql_code(p_plsql_code => l_plsql);
        END IF;

        RETURN l_result;
    END da_ajax;

    PROCEDURE log_selection (
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_app_user   IN  VARCHAR2
    ) IS
        l_string     VARCHAR2(4000);
        l_items_arr  apex_t_varchar2;
        l_page_item  VARCHAR2(50);
    BEGIN
        l_page_item := p_page_item; -- Select2 item 
        l_string := apex_util.get_session_state(l_page_item);
        IF l_string IS NOT NULL THEN
            l_items_arr := apex_string.split(p_str => l_string, p_sep => ':');
            FOR i IN 1..l_items_arr.count LOOP
                MERGE INTO plugin_suggest2_lov d
                USING (
                          SELECT
                              l_page_item        AS page_item,
                              l_items_arr(i)     AS value,
                              p_app_user         AS app_user,
                              p_app_id           AS app_id
                          FROM
                              dual
                      )
                s ON ( s.page_item = d.page_item
                       AND s.value = d.value
                       AND s.app_user = d.app_user
                       AND s.app_id = d.app_id )
                WHEN MATCHED THEN UPDATE
                SET d.capture_date = sysdate
                WHEN NOT MATCHED THEN
                INSERT (
                    capture_date,
                    app_user,
                    app_id,
                    page_item,
                    value )
                VALUES
                    ( sysdate,
                      s.app_user,
                      s.app_id,
                      s.page_item,
                      s.value );

            END LOOP;      
          
          
-- Purge

            DELETE FROM plugin_suggest2_lov
            WHERE
                    page_item = l_page_item
                AND app_user = p_app_user
                AND app_id = p_app_id
                AND ROWID NOT IN (
                    SELECT
                        ROWID
                    FROM
                        (
                            SELECT
                                h.*,
                                h.rowid
                            FROM
                                plugin_suggest2_lov h
                            WHERE
                                    h.page_item = l_page_item
                                AND h.app_user = p_app_user
                                AND h.app_id = p_app_id
                            ORDER BY
                                capture_date DESC
                        )
                    WHERE
                        ROWNUM <= 20
                );

        END IF;

    END log_selection;

    PROCEDURE delete_items (
        p_type       IN  VARCHAR2,
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_app_user   IN  VARCHAR2,
        p_id         IN  VARCHAR2
    ) IS
    BEGIN
        IF p_type = 'SINGLE' THEN
            DELETE FROM plugin_suggest2_lov h
            WHERE
                    h.app_user = app_user
                AND h.app_id = p_app_id
                AND h.page_item = p_page_item
                AND h.value = p_id;

        ELSIF p_type = 'ALL' THEN
            DELETE FROM plugin_suggest2_lov h
            WHERE
                    h.app_user = app_user
                AND h.app_id = p_app_id
                AND h.page_item = p_page_item;

        END IF;
    END delete_items;


    PROCEDURE log_selection_collection (
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER
    ) IS
        l_string        VARCHAR2(4000);
        l_items_arr     apex_t_varchar2;
        l_page_item     VARCHAR2(50);
        l_existing_seq  NUMBER;
    BEGIN
        l_page_item := p_page_item; -- Select2 item 
        l_string := apex_util.get_session_state(l_page_item);
        IF l_string IS NOT NULL THEN
            l_items_arr := apex_string.split(p_str => l_string, p_sep => ':');
            FOR i IN 1..l_items_arr.count LOOP
                BEGIN
                    SELECT
                        seq_id
                    INTO l_existing_seq
                    FROM
                        apex_collections
                    WHERE
                            collection_name = 'SUGGEST2'
                        AND c001 = l_page_item
                        AND c002 = l_items_arr(i)
                        AND n001 = p_app_id
                        AND ROWNUM = 1;

                EXCEPTION
                    WHEN no_data_found THEN
                        l_existing_seq := NULL;
                END;

                IF l_existing_seq IS NOT NULL THEN
                    apex_collection.update_member(
                        p_collection_name => 'SUGGEST2', 
                        p_seq => l_existing_seq, 
                        p_c001 => l_page_item,
                        p_c002 => l_items_arr(i),
                        p_n001 => p_app_id,
                        p_d001 => sysdate);

                ELSE
                    apex_collection.add_member(
                        p_collection_name => 'SUGGEST2', 
                        p_c001 => l_page_item, 
                        p_c002 => l_items_arr(i), 
                        p_n001 => p_app_id, 
                        p_d001 => sysdate);
                END IF;

            END LOOP;

        END IF;

    END log_selection_collection;
    
    PROCEDURE delete_items_collection (
        p_type       IN  VARCHAR2,
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_id         IN  VARCHAR2
    ) IS
    l_seq NUMBER;
    item NUMBER;
    BEGIN
 
                
    IF p_type = 'SINGLE' THEN
                   
        BEGIN
             SELECT
                    seq_id
                INTO l_seq
                FROM
                    apex_collections
                WHERE
                        collection_name = 'SUGGEST2'
                    AND c001 = p_page_item
                    AND c002 = p_id
                    AND n001 = p_app_id
                    AND ROWNUM = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_seq := NULL;
        END;
        
        APEX_COLLECTION.DELETE_MEMBER(
        p_collection_name => 'SUGGEST2',
        p_seq => l_seq);
    
    ELSIF p_type = 'ALL' THEN
    
        FOR item in (
            SELECT
                    seq_id
                FROM
                    apex_collections
                WHERE
                        collection_name = 'SUGGEST2'
                    AND c001 = p_page_item
                    AND n001 = p_app_id
        )
        LOOP 
            APEX_COLLECTION.DELETE_MEMBER(
            p_collection_name => 'SUGGEST2',
            p_seq => item.seq_id);

        END LOOP;            
                
    END IF;
  END delete_items_collection;    
  
END pkg_suggest2_plugin;
