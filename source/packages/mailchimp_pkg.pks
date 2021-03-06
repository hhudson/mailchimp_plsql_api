create or replace package mailchimp_pkg as 

--create a new mailing list
function create_list (p_list_name           in varchar2, --- the name you want to give your new mailing list
                      p_permission_reminder in varchar2) --- a sentence to remind your recipients how they got on this mailing list
                      return varchar2; --------------------- the resulting id of the newly created list & a confirmation that the operation was successful

-- add a subscriber to a subscriber list
procedure add_subscriber (  p_list_id in varchar2, --- the id of the list you are adding a subscriber to
                            p_email   in varchar2, --- the email of the new subscriber
                            p_fname   in varchar2, --- the 1st name of this subscriber
                            p_lname   in varchar2, --- the last name of this subscriber
                            p_success out boolean); -- a confirmation of that adding the subscriber was successful

-- delete subscriber from list
procedure remove_subscriber ( p_list_id in varchar2, --- the id of the list you are adding a subscriber to
                              p_email   in varchar2, --- the email of the subscriber you want to remove
                              p_success out boolean); -- a confirmation of that removing the subscriber was successful

--print list of subscribers
function get_list_of_subscribers ( p_list_id in varchar2) -- the email list_id
                                   return subscriber_typ_set PIPELINED;

--print list of merge fields for a given email list
function get_list_of_merge_fields (p_list_id in varchar2) -- the email list_id
                                   return merge_field_typ_set PIPELINED;

--create a new merge_field
procedure create_merge_field(p_list_id          in varchar2, --- the id of the list that would make use of this merge id
                             p_merge_field_tag  in varchar2, --- the name you want to give the merge variable (10 char max)
                             p_merge_field_name in varchar2, --- a more descriptive name
                             p_merge_id         out integer,
                             p_tag              out varchar2);

--update the default value of an existing merge_field
procedure update_merge_field (p_list_id         in varchar2, --- the id of the list
                              p_merge_field_tag in varchar2, --- the tag of the merge field
                              p_merge_value     in varchar2, --- the value you want to pass into the email
                              p_success         out boolean);

--create a new template
procedure create_template ( p_template_name in  varchar2, --- the name you want to give the template
                            p_html          in  clob, ------- the html of the email template
                            p_template_id   out integer); --- the id of the newly created template

-- update an existing template
procedure update_template ( p_template_id in integer, ----- the id of the pre-existing Mailchimp template that you wish to edit
                            p_html        in clob, -------- the html that you wish to pass into the above specified template
                            p_success     out boolean); --- a confirmation of whether the operation was successful
--create a new email campaign
procedure create_campaign ( p_list_id      in varchar2, ----- the list_id that should receive your email
                            p_subject_line in varchar2, ----- the subject line of your email
                            p_title        in varchar2, ----- a title for your administrative purposes
                            p_template_id  in number, ------- the template the email should use
                            p_campaign_id  out varchar2, ---- then unique id of the newly created campaign
                            p_send_url     out varchar2); --- the URL of the as-yet unsent email

--see if campaign is ready to be sent
procedure send_campaign_checklist (p_campaign_id in varchar2, --- the unique id of the campaign
                                   p_ready       out boolean); -- a confirmation of whether or not it is ready to be sent


--send email campaign
procedure send_campaign (p_send_url in varchar2, ---- the URL of the email you wish to send (see above)
                         p_success  out boolean); --- a confirmation of whether this operation was successful


-- get history of all campaigns
function get_campaign_history return campaign_history_typ_set PIPELINED;

--retrieve environment variables written to the database
function get_env_var (p_var_name in varchar2) return varchar2;

end mailchimp_pkg;
/