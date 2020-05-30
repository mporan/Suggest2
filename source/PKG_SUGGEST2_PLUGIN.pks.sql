CREATE OR REPLACE PACKAGE "PKG_SUGGEST2_PLUGIN" as

  FUNCTION render_dynamic_action(p_dynamic_action IN apex_plugin.t_dynamic_action,
                                 p_plugin         IN apex_plugin.t_plugin)
    RETURN apex_plugin.t_dynamic_action_render_result;

  FUNCTION da_ajax(p_dynamic_action IN apex_plugin.t_dynamic_action,
                   p_plugin         IN apex_plugin.t_plugin)
    RETURN apex_plugin.t_dynamic_action_ajax_result;
      
 PROCEDURE log_selection    (
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_app_user   IN  VARCHAR2);  
        
 PROCEDURE delete_items(
        p_type       IN  VARCHAR2,
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_app_user   IN  VARCHAR2,
        p_id         IN  VARCHAR2);

 PROCEDURE log_selection_collection    (
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER);  

 PROCEDURE delete_items_collection(
        p_type       IN  VARCHAR2,
        p_page_item  IN  VARCHAR2,
        p_app_id     IN  NUMBER,
        p_id         IN  VARCHAR2);
        
END PKG_SUGGEST2_PLUGIN;
