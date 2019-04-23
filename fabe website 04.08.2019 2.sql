set serveroutput on
declare
l_listid       varchar2(50) := '5da68a7259';
l_myemail      varchar2(50) := 'hhudson@fab.earth';
l_firstname    varchar2(50) := 'Holden';
l_lastname     varchar2(50) := 'Caulfield';
l_add_sub      boolean;
l_subject_line varchar2(500) := 'Thanks for creating another action';
l_templateid   number := 67935;
l_campaignid   varchar2(50);
l_send_url     varchar2(500);
l_ready        boolean;
l_sent         boolean;
l_removed      boolean;
begin
  mailchimp_pkg.add_subscriber (p_list_id => l_listid,
                                p_email   => l_myemail,
                                p_fname   => l_firstname,
                                p_lname   => l_lastname,
                                p_success => l_add_sub);
  if l_add_sub then
    dbms_output.put_line('added subscriber');
    mailchimp_pkg.create_campaign ( p_list_id      => l_listid,
                                    p_subject_line => l_subject_line,
                                    p_title        => l_subject_line,
                                    p_template_id  => l_templateid,
                                    p_campaign_id  => l_campaignid,
                                    p_send_url     => l_send_url);
    dbms_output.put_line('l_campaignid :'||l_campaignid);
    dbms_output.put_line('l_send_url :'||l_send_url);
    mailchimp_pkg.send_campaign_checklist (p_campaign_id => l_campaignid,
                                           p_ready       => l_ready);
  
      if l_ready then
        dbms_output.put_line('campaign ready');
        mailchimp_pkg.send_campaign (p_send_url => l_send_url,
                                     p_success  => l_sent);
          if l_sent then
            dbms_output.put_line('sent');
            mailchimp_pkg.remove_subscriber ( p_list_id => l_listid,
                                              p_email   => l_myemail,
                                              p_success => l_removed);
            if l_removed then
              dbms_output.put_line('removed subscriber');
            else 
              dbms_output.put_line('failed to remove subscriber');
            end if;
          else
            dbms_output.put_line('failed to send');
          end if;
      else 
        dbms_output.put_line('campaign not ready');
      end if;
  else
    dbms_output.put_line('failed to add subscriber');
  end if;
end;