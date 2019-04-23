set serveroutput on
declare
l_listid varchar2(50);
begin
   l_listid := mailchimp_pkg.create_list (p_list_name           => 'test list 04.08.2019',
                                          p_permission_reminder => 'you created an action');
   dbms_output.put_line('list id: '||l_listid); --af6228aa95
end;
/
declare
l_listid  varchar2(50) := 'af6228aa95';
l_add_sub boolean;
begin
 mailchimp_pkg.add_subscriber ( p_list_id => l_listid,
                                p_email   => 'haydenhhudson@gmail.com',
                                p_fname   => 'Hayden',
                                p_lname   => 'Hudson',
                                p_success => l_add_sub);
  if l_add_sub then
    dbms_output.put_line('added subscriber');
  else
    dbms_output.put_line('failed to add subscriber');
  end if;
end;
/
declare
l_listid     varchar2(50) := 'af6228aa95';
l_templateid number := 67935;
l_campaignid varchar2(50);
l_url        varchar2(500);
begin
  mailchimp_pkg.create_campaign (   p_list_id      => l_listid,
                                    p_subject_line => 'test email 04.08.2019',
                                    p_title        => 'test email 04.08.2019',
                                    p_template_id  => l_templateid,
                                    p_campaign_id  => l_campaignid,
                                    p_send_url     => l_url);
    
    dbms_output.put_line('l_campaignid :'||l_campaignid);
    dbms_output.put_line('l_url :'||l_url);
    /*
    l_campaignid :a487e527db
    l_url :https://us19.api.mailchimp.com/3.0/campaigns/a487e527db/actions/send
    */
end;
/
declare
l_campaignid varchar2(50) := 'a487e527db';
l_ready      boolean;
begin
  mailchimp_pkg.send_campaign_checklist (p_campaign_id => l_campaignid,
                                         p_ready       => l_ready);
  
  if l_ready then
    dbms_output.put_line('ready');
  else 
    dbms_output.put_line('not ready');
  end if;
end;  
/
declare
l_send_url varchar2(500) := 'https://us19.api.mailchimp.com/3.0/campaigns/a487e527db/actions/send';
l_success  boolean;
begin
mailchimp_pkg.send_campaign (p_send_url => l_send_url,
                             p_success  => l_success);
  if l_success then
    dbms_output.put_line('sent');
  else
    dbms_output.put_line('failed to send');
  end if;
end;
