
# Suggest2 Plug-In

![APEX Plugin](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/b7e95341/badges/apex-plugin-badge.svg)
![APEX Built with Love](https://cdn.rawgit.com/Dani3lSun/apex-github-badges/7919f913/badges/apex-love-badge.svg)

Extend Oracle APEX [Select2](https://github.com/nbuytaert1/apex-select2) plug-in with suggestions!

- Offer users previous/popular selections before they start typing
- Display custom HTML inside Select2 dropdown
- Items can be deleted by users

![Preview](https://github.com/mporan/Suggest2/blob/master/Suggest2-preview.gif)

## Demo
[View Demo](https://apex.oracle.com/pls/apex/poran/r/suggest2/)

## Table of Contents

* [How it works](#how-it-works)
* [Install](#install)
* [Plug-in Settings](#plug-in-settings)
* [Quickstart Setup](#quickstart-setup)
  * [Option A - Database table](#option-a---database-table)
  * [Option B - APEX Collection](#option-b---apex-collection)


## How it works
* After clicking a Select2 page item, suggestions appear inside the dropdown.
* Clicking a suggestion sets the value of Select2 page item.
* Once the user starts typing, the suggestions are replaced with Select2 results (Similar to the behavior of Google's search box).
* Suggestions are generated using a custom SQL query that returns a subset of select2 list of values return values. This query runs after page is loaded to prevent delay (AJAX).
* 'Remove' action triggers custom PL/SQL from plug-in settings using AJAX. No page reload needed.

## Install
1. Import plug-in file 'dynamic_action_plugin_apexux_mporan_suggest2.sql' from 'source' directory into your application.
2. Import package from 'source' directory to database (better performance). Alternatively paste the functions render_dynamic_action and da_ajax into the plug-in's source PL/SQL and remove package name from callbacks.
3. Optional: For better performance copy css and js files from 'server' directory to server and call them on 'File URLs to Load'.
4. Create a new dynamic action for a “Page Load” event.
5. For True action select “Suggest2 [Plug-In]”.
6. On plug-in settings, assign target Select2 item and provide a query or custom HTML (see Plug-in Setting).


## Plug-in Settings

- **Target Select2 Page Item**
  - Suggest2 will be added to this Select2 page item. APEX [Select2](https://github.com/nbuytaert1/apex-select2) plug-in must be installed.
- **Title**
  - Title to appear on top of suggestion items. Default value: 'Suggestions'.
- **SQL Query for Suggestions**
  - The query needs to return a display column and a return column, consistent with Select2 list of values.
  - Return column value will be used to set value on Select2 page item.
  - Substitution string @PAGE\_ITEM@ will be replaced by plug-in with selected target Select2 page item name (e.g. P3\_EMP).
- **Number of Items to Display -** Up to 20 items.
- **Display 'Remove' Buttons** (Y/N) - Allow users to delete suggestion items.
- **PL/SQL to Remove Single Items** - This executes when users click 'Remove'.  
  Substitution strings:  
  @ID@ will be replaced by plug-in with the return value of item to delete.  
  @PAGE\_ITEM@ will be replaced by plug-in with selected target Select2 page item name.

- **PL/SQL to Remove ALL Items** - This executes when users click 'Remove All'.
 Substitution strings:  
 @PAGE\_ITEM@ will be replaced by plug-in with selected target Select2 page item name.
- **Rapid Selection (For Multi-Value)** (Y/N) – Similar to Select2 Rapid Selection option. The dropdown keeps open after an item is selected, allowing for rapid selection of multiple items.
- **Icon Class** – Icon to appear before items. Use CSS class of Font APEX/Font awesome (See https://apex.oracle.com/ut.). Leave null for none.
- **Custom HTML** – Display custom content inside dropdown. Can be useful for search tips or in-context actions.

The information above is available in the built-in help text in APEX Page Designer.


## Quickstart Setup
You may use the following steps to start capturing user’s selection history and integrate it in the plug-in.
This example utilizes the procedures that are included in the plug-in package.
Basically the plug-in requires only a query. You are free to use any other method that fits your needs to display suggestions.

### Option A - Database table
This is the preferred option. History is kept on a table and is available across sessions.

1.	Create a table to capture selections.
```sql
CREATE TABLE "PLUGIN_SUGGEST2_LOV"
   ("CAPTURE_DATE" DATE,
    "APP_USER" 	   VARCHAR2(30) NOT NULL,
    "APP_ID" 	   NUMBER NOT NULL,
    "PAGE_ITEM"    VARCHAR2(30) NOT NULL,
    "VALUE" 	   VARCHAR2(200) NOT NULL
   )  
````

2.	Create a page process on 'Processing' stage to log Select2 page item submitted value:
```sql
PKG_SUGGEST2_PLUGIN.LOG_SELECTION    (
        p_page_item  => 'P1_EMP', -- Select2 Item
        p_app_id     => :app_id ,
        p_app_user   => :app_user
    );
```
3.	Add plug-in to page (see [Install](#install) steps 4-6).
4.	On plug-in settings, for “SQL Query for Suggestions” use the following query:
```sql
WITH select2_lov AS (
 --Put here the “List of Values” query of target select2:
 SELECT
   e.first_name || ' ' || e.last_name AS d,
   e.employee_id AS r
 FROM
   oehr_employees e
)

SELECT
 s2.d,
 s2.r
FROM
 plugin_suggest2_lov h,
 select2_lov s2
WHERE
 s2.r = h.value
 AND h.app_user  = :app_user
 AND h.app_id    = :app_id
 AND h.page_item = '@PAGE_ITEM@' -- substitution string
ORDER BY
 capture_date DESC;
```

5.	‘Display “Remove” Buttons’: Yes
6.	‘PL/SQL to Remove Single Items’:
```sql
PKG_SUGGEST2_PLUGIN.DELETE_ITEMS(
    P_TYPE      => 'SINGLE',
    P_PAGE_ITEM => '@PAGE_ITEM@',
    P_APP_ID    => :app_id,
    P_APP_USER  => :app_user,
    P_ID        => '@ID@'
  );
```
7.	 “PL/SQL to Remove ALL Items”:
```sql
PKG_SUGGEST2_PLUGIN.DELETE_ITEMS(
    P_TYPE      => 'ALL',
    P_PAGE_ITEM => '@PAGE_ITEM@',
    P_APP_ID    => :app_id,
    P_APP_USER  => :app_user,
    P_ID        => null
  );
```


### Option B - APEX Collection
This option is used to log selections to a temporary APEX Collection. The main drawback is that items are not saved for future sessions.
This technique is used on this plug-in’s demo app.
1.	 Create a page process on ‘Before Header’ stage to create a collection to log selections.
```sql
begin
 if not apex_collection.collection_exists('SUGGEST2') then
  apex_collection.create_collection('SUGGEST2');
 end if;
end;
```

2.	Create a page process on 'Processing' stage to log Select2 page item submitted value:
```sql
PKG_SUGGEST2_PLUGIN.LOG_SELECTION_COLLECTION (
        p_page_item  => 'P2_EMP', -- Select2 Item
        p_app_id     => :app_id
    );
```
3.	Add plug-in to page (see [Install](#install) steps 4-6).
4.	On plug-in settings, for “SQL Query for Suggestions” use the following query:
```sql
WITH select2_lov AS (
--Put here the “List of Values” query of target select2:
 SELECT
   e.first_name || ' ' || e.last_name AS d,
   e.employee_id AS r
 FROM
   oehr_employees e
)

SELECT
 s2.d,
 s2.r
FROM
 apex_collections h,
 select2_lov s2
WHERE
     h.collection_name = 'SUGGEST2'
 AND s2.r   = h.c002
 AND h.n001 = :app_id
 AND h.c001 = '@PAGE_ITEM@' -- substitution string
ORDER BY
h.d001 DESC;
```  

5. ‘Display “Remove” Buttons’: Yes
6. ‘PL/SQL to Remove Single Items’:

```sql
PKG_SUGGEST2_PLUGIN.DELETE_ITEMS_COLLECTION(
    P_TYPE      => 'SINGLE',
    P_PAGE_ITEM => '@PAGE_ITEM@',
    P_APP_ID    => :app_id,
    P_ID        => '@ID@'
  );
```

7.  “PL/SQL to Remove ALL Items”:
```sql
PKG_SUGGEST2_PLUGIN.DELETE_ITEMS_COLLECTION (
    P_TYPE      => 'ALL',
    P_PAGE_ITEM => '@PAGE_ITEM@',
    P_APP_ID    => :app_id,
    P_ID        => null
  );
```
