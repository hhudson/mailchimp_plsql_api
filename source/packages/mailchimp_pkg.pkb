create or replace package body mailchimp_pkg as 
    
    gc_scope_prefix constant varchar2(31)  := lower($$plsql_unit) || '.'; ----------------- necessary for the logger implementation
    g_url_prefix    constant varchar2(100) := get_env_var (p_var_name => 'url_prefix'); --- your Mailchimp url prefix, in the format 'https://us[XX].api.mailchimp.com/3.0/'
    g_password      constant varchar2(50)  := get_env_var (p_var_name => 'api_key'); ------ this is your API Key (very sensitive - keep to yourself)
    g_wallet_path   constant varchar2(100) := get_env_var (p_var_name => 'wallet_path'); --  the path on to your Oracle Wallet, syntax 'file:[path to your Oracle Wallet]'
    g_https_host    constant varchar2(100) := get_env_var (p_var_name => 'https_host'); --- necessary if you have an Oracle 12.2 database or higher (see instructions)
    g_address1      constant varchar2(500) := get_env_var (p_var_name => 'address1'); ----- the CAN SPAM act requires that you specify the organization's address
    g_city          constant varchar2(500) := get_env_var (p_var_name => 'city'); --------- the CAN SPAM act requires that you specify the organization's address
    g_state         constant varchar2(500) := get_env_var (p_var_name => 'state'); -------- the CAN SPAM act requires that you specify the organization's address
    g_zip           constant varchar2(500) := get_env_var (p_var_name => 'zip'); ---------- the CAN SPAM act requires that you specify the organization's address
    g_county        constant varchar2(500) := get_env_var (p_var_name => 'country'); ------ the CAN SPAM act requires that you specify the organization's address
    g_company_name  constant varchar2(100) := get_env_var (p_var_name => 'company'); ------ whatever your organization is called
    g_reply_to      constant varchar2(100) := get_env_var (p_var_name => 'email'); -------- the email that you've authenticated with Mailchimp
    g_from_name     constant varchar2(100) := get_env_var (p_var_name => 'from_name'); ---- the name your emails will appear to be from
    g_username      constant varchar2(50)  := 'admin'; ------------------------------------ arbitrary - can be anything

-- see package specs
function create_list (p_list_name           in varchar2, 
                      p_permission_reminder in varchar2) 
                      return varchar2
is 
l_scope logger_logs.scope%type := gc_scope_prefix || 'create_list';
l_params logger.tab_param;
l_body         varchar2(1000);
l_response     clob;
l_confirmation varchar2(1000);
l_list_id      varchar2(50);
begin
  logger.append_param(l_params, 'p_list_name', p_list_name);
  logger.append_param(l_params, 'p_permission_reminder', p_permission_reminder);
  logger.log('START', l_scope, null, l_params);

    l_body := '{"name":"'||p_list_name||'","contact":{"company":"'||g_company_name||'","address1":"'||g_address1||'","city":"'||g_city||'","state":"'||g_state||'","zip":"'||g_zip||'","country":"'||g_county||'","phone":""}';
    l_body := l_body||',"permission_reminder":"'||p_permission_reminder||'","campaign_defaults":{"from_name":"'||g_from_name||'''","from_email":"'||g_reply_to||'","subject":"","language":"en"},"email_type_option":true}';
    
    logger.log('l_body :', l_scope, l_body);

    l_response := apex_web_service.make_rest_request(
          p_url         => g_url_prefix||'/lists/'
        , p_http_method => 'POST'
        , p_username    => g_username
        , p_password    => g_password
        , p_body        => l_body
        , p_wallet_path => g_wallet_path
        , p_https_host  => g_https_host
    );

    l_list_id := json_value(l_response, '$.id');

    logger.log('list id :'    , l_scope, l_list_id);
    logger.log('l_response : ', l_scope, l_response);

  logger.log('END', l_scope);
  return l_list_id;
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end create_list;

-- see package specs
procedure add_subscriber (  p_list_id in varchar2,
                            p_email   in varchar2,
                            p_fname   in varchar2,
                            p_lname   in varchar2,
                            p_success out boolean)
is 
l_scope        logger_logs.scope%type := gc_scope_prefix || 'add_subscriber';
l_params       logger.tab_param;
l_body         varchar2(1000);
l_response     clob;
l_confirmation varchar2(1000);
begin
    logger.append_param(l_params, 'p_list_id', p_list_id);
    logger.append_param(l_params, 'p_email', p_email);
    logger.append_param(l_params, 'p_fname', p_fname);
    logger.append_param(l_params, 'p_lname', p_lname);
    logger.log('START', l_scope, null, l_params);

    l_body := '{"email_address":"'||p_email||'","status":"subscribed","merge_fields":{"FNAME":"'||p_fname||'","LNAME":"'||p_lname||'"}}';

    l_response := apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/lists/'||p_list_id||'/members/'
                , p_http_method => 'POST'
                , p_username    => g_username
                , p_password    => g_password
                , p_body        => l_body
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    l_confirmation := json_value(l_response, '$.status');
    

    if l_confirmation = 'subscribed' then
        p_success := true;
        logger.log('Success! :', l_scope, l_confirmation);
    else 
        p_success := false;
        logger.log('Failure :', l_scope, l_response);
    end if;

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end add_subscriber;

-- see package specs
procedure remove_subscriber ( p_list_id in varchar2, 
                              p_email   in varchar2, 
                              p_success out boolean)
is 
l_scope           logger_logs.scope%type := gc_scope_prefix || 'remove_subscriber';
l_params          logger.tab_param;
l_response        clob;
l_subscriber_hash varchar2(200);
l_confirmation    varchar2(1000);
l_count           number;
begin
    logger.append_param(l_params, 'p_list_id', p_list_id);
    logger.append_param(l_params, 'p_email', p_email);
    logger.log('START', l_scope, null, l_params);

    select standard_hash(p_email, 'MD5')
    into l_subscriber_hash
    from dual;

    l_response := apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/lists/'||p_list_id||'/members/'||l_subscriber_hash
                , p_http_method => 'DELETE'
                , p_username    => g_username
                , p_password    => g_password
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    SELECT count(*)
        into l_count
        from table(mailchimp_pkg.get_list_of_subscribers ( p_list_id => p_list_id))
        where email_address = p_email;
    
    if l_count = 0 then
        p_success := true;
    else 
        p_success := false;
    end if;
    
    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end remove_subscriber;

-- see package specs
function get_list_of_subscribers ( p_list_id in varchar2) -- the email list_id
                                   RETURN subscriber_typ_set PIPELINED
is 
TYPE subscriber_table IS table of subscriber_typ_TBL%ROWTYPE INDEX BY PLS_INTEGER;
l_scope         logger_logs.scope%type := gc_scope_prefix || 'get_list_of_subscribers';
l_params        logger.tab_param;
l_subscriber_set subscriber_table;
l_subscribers    subscriber_typ_set := subscriber_typ_set();
l_response       clob;
l_total_items    integer;
l_counter        integer;
begin
  logger.append_param(l_params, 'p_list_id', p_list_id);
  logger.log('START', l_scope, null, l_params);
  
  l_response:= apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/lists/'||p_list_id||'/members?offset=0&count=10000'
                , p_http_method => 'GET'
                , p_username    => g_username
                , p_password    => g_password
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

  l_total_items := json_value(l_response, '$.total_items');
  logger.log('l_total_items :', l_scope, to_char(l_total_items));

  for i in 1..l_total_items 
  loop
    l_counter := i -1;
    l_subscriber_set(i).email_address := json_value(l_response, '$.members['||l_counter||'].email_address');
    l_subscriber_set(i).first_name    := json_value(l_response, '$.members['||l_counter||'].merge_fields.FNAME');
    l_subscriber_set(i).last_name     := json_value(l_response, '$.members['||l_counter||'].merge_fields.LNAME');
    l_subscriber_set(i).status        := json_value(l_response, '$.members['||l_counter||'].status');
    
  end loop;

  for i in 1..l_total_items 
  loop
  PIPE ROW (subscriber_typ(l_subscriber_set(i).email_address,
                           l_subscriber_set(i).first_name,
                           l_subscriber_set(i).last_name,
                           l_subscriber_set(i).status
                          )
           );
  end loop;

  logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end get_list_of_subscribers;

--see package specs
function get_list_of_merge_fields (p_list_id in varchar2)
                                   return merge_field_typ_set PIPELINED
is 
TYPE merge_field_table IS table of merge_field_typ_tbl%ROWTYPE INDEX BY PLS_INTEGER;
l_scope logger_logs.scope%type := gc_scope_prefix || 'get_list_of_merge_fields';
l_params logger.tab_param;
l_merge_field_set merge_field_table;
l_merge_fields    merge_field_typ_set := merge_field_typ_set();
l_response       clob;
l_total_items    integer;
l_counter        integer;
begin
    logger.append_param(l_params, 'p_list_id', p_list_id);
    logger.log('START', l_scope, null, l_params);

    l_response:= apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/lists/'||p_list_id||'/merge-fields/'
                , p_http_method => 'GET'
                , p_username    => g_username
                , p_password    => g_password
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    l_total_items := json_value(l_response, '$.total_items');
    logger.log('l_total_items :', l_scope, to_char(l_total_items));

    for i in 1..l_total_items 
    loop
        l_counter := i -1;
        l_merge_field_set(i).merge_id      := json_value(l_response, '$.merge_fields['||l_counter||'].merge_id');
        l_merge_field_set(i).tag           := json_value(l_response, '$.merge_fields['||l_counter||'].tag');
        l_merge_field_set(i).name          := json_value(l_response, '$.merge_fields['||l_counter||'].name');
        l_merge_field_set(i).default_value := json_value(l_response, '$.merge_fields['||l_counter||'].default_value');
    end loop;

    for i in 1..l_total_items 
    loop
    PIPE ROW (merge_field_typ(l_merge_field_set(i).merge_id,
                              l_merge_field_set(i).tag,
                              l_merge_field_set(i).name,
                              l_merge_field_set(i).default_value
                              )
             );
    end loop;
    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end get_list_of_merge_fields;

-- see package specs
procedure create_merge_field(p_list_id          in varchar2,
                             p_merge_field_tag  in varchar2,
                             p_merge_field_name in varchar2,
                             p_merge_id         out integer,
                             p_tag              out varchar2)
is 
l_scope     logger_logs.scope%type := gc_scope_prefix || 'create_merge_field';
l_params    logger.tab_param;
l_body      varchar2(1000);
l_response  varchar2(2000);
l_tag_count number;
    procedure check_if_already_there is 
    begin
        SELECT     merge_id,   tag
            INTO p_merge_id, p_tag
            FROM TABLE(mailchimp_pkg.get_list_of_merge_fields(p_list_id => p_list_id))
            where tag = p_merge_field_tag;
            logger.log('The tag already exists in this list.', l_scope, null, l_params);
            logger.log('p_merge_id :', l_scope, to_char(p_merge_id));
            logger.log('p_tag :'     , l_scope, p_tag);
        exception when no_data_found then
            logger.log('The tag does not exist yet in this list', l_scope, null, l_params);
    end check_if_already_there;
begin 
    logger.append_param(l_params, 'p_list_id', p_list_id);
    logger.append_param(l_params, 'p_merge_field_tag', p_merge_field_tag);
    logger.append_param(l_params, 'p_merge_field_name', p_merge_field_name);
    logger.log('START', l_scope, null, l_params);

    if length(p_merge_field_tag) > 10 then
        logger.log_error('p_merge_field_tag cannot be more than 10 characters.', l_scope, null, l_params);
        raise_application_error(-20456, 'Merge field too long');
    end if;

    check_if_already_there;
    if p_merge_id is not null then return; end if;

    l_body := '{"tag":"'||p_merge_field_tag||'", "name":"'||p_merge_field_name||'", "type":"text"}';

    l_response := apex_web_service.make_rest_request(
          p_url         => g_url_prefix||'lists/'||p_list_id||'/merge-fields/'
        , p_http_method => 'POST'
        , p_username    => g_username 
        , p_password    => g_password
        , p_body        => l_body
        , p_wallet_path => g_wallet_path
        , p_https_host  => g_https_host
    );
    
    p_merge_id := json_value(l_response, '$.merge_id');
    p_tag      := json_value(l_response, '$.tag');

    if p_merge_id is null then
        logger.log_error('Unhandled Error :', l_scope, l_response);
    else 
        logger.log('p_merge_id :', l_scope, to_char(p_merge_id));
        logger.log('p_tag :'     , l_scope, p_tag);
    end if;

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end create_merge_field;

-- see package specs
procedure update_merge_field (p_list_id         in varchar2,
                              p_merge_field_tag in varchar2,
                              p_merge_value     in varchar2,
                              p_success         out boolean)
is 
l_scope        logger_logs.scope%type := gc_scope_prefix || 'update_merge_field';
l_params       logger.tab_param;
l_merge_id     integer;
l_body         varchar2(1000);
l_response     clob;
l_confirmation varchar2(1000);
begin
  logger.append_param(l_params, 'p_list_id', p_list_id);
  logger.append_param(l_params, 'p_merge_field_tag', p_merge_field_tag);
  logger.append_param(l_params, 'p_merge_value', p_merge_value);
  logger.log('START', l_scope, null, l_params);
    
    begin
      select merge_id
        into l_merge_id 
        from table(mailchimp_pkg.get_list_of_merge_fields(p_list_id => p_list_id))
        where tag = p_merge_field_tag;
    exception when no_data_found then
      logger.log_error('Tag does not exist in this list. It must be created 1st.', l_scope, null, l_params); 
      raise;
    end;

    l_body := '{"name":"'||p_merge_field_tag||'", "type":"text", "default_value": "'||p_merge_value||'", "options": {"size": 2000}}';

        l_response := apex_web_service.make_rest_request(
                p_url         => g_url_prefix||'/lists/'||p_list_id||'/merge-fields/'||l_merge_id
                , p_http_method => 'PATCH'
                , p_username    => g_username
                , p_password    => g_password
                , p_body        => l_body
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    l_confirmation := json_value(l_response, '$.default_value');
    

    if l_confirmation = p_merge_value then
        p_success := true;
        logger.log('Successfully updated merge field to :', l_scope, l_confirmation);
    else 
        p_success := false;
        logger.log('Failure :', l_scope, l_confirmation);
    end if;


  logger.log('END', l_scope);
  exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end update_merge_field;

-- see package specs
procedure create_template ( p_template_name in  varchar2, 
                            p_html          in  clob, 
                            p_template_id   out integer)
is 
l_scope    logger_logs.scope%type := gc_scope_prefix || 'create_template';
l_params   logger.tab_param;
l_body     varchar2(1000);
l_response clob;
begin
  logger.append_param(l_params, 'p_template_name', p_template_name);
  logger.log('START', l_scope, null, l_params);

    l_body := '{"name":"'||p_template_name||'","html":"'||p_html||'"}';    
    l_response := apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/templates'
                , p_http_method => 'POST'
                , p_username    => g_username
                , p_password    => g_password
                , p_body        => l_body
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );
    
    p_template_id := json_value(l_response, '$.id');
    logger.log('p_template_id :', l_scope, to_char(p_template_id));

  logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end create_template;

-- see package specs
procedure update_template ( p_template_id in integer,
                            p_html        in clob,
                            p_success     out boolean)
is
l_scope       logger_logs.scope%type := gc_scope_prefix || 'update_template';
l_params      logger.tab_param;
l_body        clob;
l_response    clob;
l_template_id integer;
begin
    logger.append_param(l_params, 'p_template_id', p_template_id);
    logger.log('START', l_scope, null, l_params);
    
    l_body := '{"html":"'||p_html||'"}';

    l_response := apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/templates/'||p_template_id
                , p_http_method => 'PATCH'
                , p_username    => g_username
                , p_password    => g_password
                , p_body        => l_body
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    l_template_id := json_value(l_response, '$.id');

    if l_template_id = p_template_id then
        p_success := true;
    else
        p_success := false;
    end if;

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end update_template;

-- see package specs
procedure create_campaign ( p_list_id      in varchar2,
                            p_subject_line in varchar2,
                            p_title        in varchar2,
                            p_template_id  in number,
                            p_send_url     out varchar2)
is
l_scope       logger_logs.scope%type := gc_scope_prefix || 'create_campaign'; 
l_params      logger.tab_param;
l_body        varchar2(1000);
l_response    clob;
l_campaign_id varchar2(100);
begin
    logger.append_param(l_params, 'p_list_id', p_list_id);
    logger.append_param(l_params, 'p_subject_line', p_subject_line);
    logger.append_param(l_params, 'p_title', p_title);
    logger.append_param(l_params, 'p_template_id', p_template_id);
    logger.append_param(l_params, 'g_reply_to', g_reply_to);
    logger.append_param(l_params, 'g_from_name', g_from_name);
    logger.append_param(l_params, 'p_send_url', p_send_url);
    logger.log('START', l_scope, null, l_params);
    l_body         := '{"recipients":{"list_id":"'||p_list_id||'"},"type":"regular","settings":{"subject_line":"'||p_subject_line||'", "title": "'||p_title||'","template_id": '||p_template_id||',"reply_to":"'||g_reply_to||'","from_name":"'||g_from_name||'"}}';

    l_response := apex_web_service.make_rest_request(
                      p_url         => g_url_prefix||'/campaigns'
                    , p_http_method => 'POST'
                    , p_username    => g_username
                    , p_password    => g_password
                    , p_body        => l_body
                    , p_wallet_path => g_wallet_path
                    , p_https_host  => g_https_host
                );

    l_campaign_id := json_value(l_response, '$.id');
    logger.log('l_campaign_id :', l_scope, l_campaign_id);
    p_send_url := json_value(l_response, '$."_links"[3].href');
    logger.log('p_send_url :', l_scope, p_send_url);

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params);
    raise;
end create_campaign;

-- see package specs
procedure send_campaign (p_send_url in varchar2,
                         p_success  out boolean)
is 
l_scope    logger_logs.scope%type := gc_scope_prefix || 'send_campaign';
l_params   logger.tab_param;
l_response clob;
begin
    logger.append_param(l_params, 'p_send_url', p_send_url);
    logger.log('START', l_scope, null, l_params);

    l_response := apex_web_service.make_rest_request(
                          p_url         => p_send_url
                        , p_http_method => 'POST'
                        , p_username    => g_username
                        , p_password    => g_password
                        , p_wallet_path => g_wallet_path
                        , p_https_host  => g_https_host
                    );
    
    if length(l_response) = 0 then
        p_success := true;
        logger.log('Success!', l_scope, null, l_params);
    else 
        p_success := false;
        logger.log('l_response :', l_scope, l_response);
    end if;

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end send_campaign;

function get_campaign_history return campaign_history_typ_set PIPELINED
is 
TYPE campaign_table IS table of campaign_history_typ_tbl%ROWTYPE INDEX BY PLS_INTEGER;
l_scope logger_logs.scope%type := gc_scope_prefix || 'get_campaign_history';
l_params logger.tab_param;
l_campaign_set   campaign_table;
l_campaigns      campaign_history_typ_set := campaign_history_typ_set();
l_response       clob;
l_total_items    integer;
l_counter        integer;
l_send_time      varchar2(100);
begin
    logger.log('START', l_scope, null, l_params);

    l_response:= apex_web_service.make_rest_request(
                  p_url         => g_url_prefix||'/campaigns/'
                , p_http_method => 'GET'
                , p_username    => g_username
                , p_password    => g_password
                , p_wallet_path => g_wallet_path
                , p_https_host  => g_https_host
            );

    l_total_items := json_value(l_response, '$.total_items');
    logger.log('l_total_items :', l_scope, to_char(l_total_items));

    for i in 1..l_total_items 
  loop
    l_counter := i -1;
    l_campaign_set(i).campaign_id       := json_value(l_response, '$.campaigns['||l_counter||'].id');
    l_campaign_set(i).emails_sent       := json_value(l_response, '$.campaigns['||l_counter||'].emails_sent');
    l_send_time                         := json_value(l_response, '$.campaigns['||l_counter||'].send_time');
    l_campaign_set(i).send_time         := to_date(substr(l_send_time,1,instr(l_send_time,'+')-1), 'YYYY-MM-DD"T"HH24:MI:SS');
    l_campaign_set(i).recipient_list_id := json_value(l_response, '$.campaigns['||l_counter||'].recipients.list_id');
    l_campaign_set(i).template_id       := json_value(l_response, '$.campaigns['||l_counter||'].settings.template_id');
    l_campaign_set(i).subject_line      := json_value(l_response, '$.campaigns['||l_counter||'].settings.subject_line');
    l_campaign_set(i).from_name         := json_value(l_response, '$.campaigns['||l_counter||'].settings.from_name');
    l_campaign_set(i).opens             := json_value(l_response, '$.campaigns['||l_counter||'].report_summary.opens');
    l_campaign_set(i).unique_opens      := json_value(l_response, '$.campaigns['||l_counter||'].report_summary.unique_opens');
    l_campaign_set(i).open_rate         := json_value(l_response, '$.campaigns['||l_counter||'].report_summary.open_rate');
    l_campaign_set(i).clicks            := json_value(l_response, '$.campaigns['||l_counter||'].report_summary.clicks');
    l_campaign_set(i).cancel_send       := json_value(l_response, '$.campaigns['||l_counter||']."_links"[4].href');
  end loop;

  for i in 1..l_total_items 
  loop
  PIPE ROW (campaign_history_typ(l_campaign_set(i).campaign_id,
                                 l_campaign_set(i).emails_sent,
                                 l_campaign_set(i).send_time,
                                 l_campaign_set(i).recipient_list_id,
                                 l_campaign_set(i).template_id,
                                 l_campaign_set(i).subject_line,
                                 l_campaign_set(i).from_name,
                                 l_campaign_set(i).opens,
                                 l_campaign_set(i).unique_opens,
                                 l_campaign_set(i).open_rate,
                                 l_campaign_set(i).clicks,
                                 l_campaign_set(i).cancel_send
                          )
           );
  end loop;

    logger.log('END', l_scope);
exception when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params); 
    raise;
end get_campaign_history;

-- see package specs
function get_env_var (p_var_name in varchar2) return varchar2
is 
l_scope   logger_logs.scope%type := gc_scope_prefix || 'get_env_var';
l_params  logger.tab_param;
l_var_val varchar2(200);
begin 
    logger.append_param(l_params, 'p_var_name', p_var_name);
    logger.log('START', l_scope, null, l_params);

    select variable_value
        into l_var_val
        from mailchimp_env_var
        where upper(variable_name) = upper(p_var_name);

    logger.log('END', l_scope);
    return l_var_val;
exception 
    when no_data_found then
        logger.log_error('Variable name not recognized.', l_scope, null, l_params); 
        return null;
    when others then 
        logger.log_error('Unhandled Exception', l_scope, null, l_params); 
        raise;
end get_env_var;

end mailchimp_pkg;
/