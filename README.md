# MailChimp PL/SQL API
Interact with the MailChimp API using PL/SQL.

### Benefits of using MailChimp
Using MailChimp has many advantages:
- Deliverabity & Reputation : 
    MailChimp makes it easy for you to craft mail that complies will all the highest standards of the [CAN-SPAM](https://mailchimp.com/help/anti-spam-requirements-for-email/) act and signals to email providers that your mail is legitimate.
- Free (for my purposes):
    At the time of this writing, if you have fewer than 2,000 subscribers and send fewer than 12,000 emails / month, there's no expiring trial, contract or credit card required. Your emails will have a small amount of MailChimp branding at the bottom (see screenshot at the end of this post) but nothing that offends me.
- Easily craft handsome & robust email templates: 
    Worrying about how your email will render across different email clients is a drag. MailChimp defaults are certainly better than anything I'm going to design myself.
- Sophisticated reporting
- And, obviously, no need to setup and maintain my own email server. 



# Prerequisites
## Enable your database to talk to MailChimp
### Import the necessary certificates
You'll need to import the certificate chain (not the end certificate) to your Oracle Wallet for the website usXX.api.mailchimp.com (e.g. us18.api.mailchimp.com).

Proof that you've successfully configured your database to talk to the MailChimp API is to be able to run the following without error:
```
select apex_web_service.make_rest_request(
      p_url         => 'https://us18.api.mailchimp.com'
    , p_http_method => 'GET' 
    , p_wallet_path => 'file:[path to your oracle wallet]' 
    ) from dual;

```
If you get the error 'ORA-29024: Certificate validation failure', it must be because you have not imported the certificate chain referenced above to your linked oracle wallet. See my notes on [how I configured my Oracle Wallet](docs/Create_oracle_wallet.md). 

If you get the error 'ORA-24263: Certificate of the remote server does not match the target address.', it must mean that you are on a 12.2 database (or higher) and you need to add a parameter to your request:
```
select apex_web_service.make_rest_request(
      p_url         => 'https://us18.api.mailchimp.com'
    , p_http_method => 'GET' 
    , p_wallet_path => 'file:/home/oracle/orapki_wallet_nowc' 
    , p_https_host  => 'wildcardsan2.mailchimp.com'
    ) from dual;
```
The 'HTTPS Host' refers to 'Common Name' of the URL you are trying to reach and must now be specified when it does not match the destination URL. See my notes on [solving the ORA-24263 error](docs/Certificate_of_the_remote_server_does_not_match_the_target_address.md). 

## Install Logger

It would of course be perfectly possible to write this PL/SQL package without reference to Logger. Nonetheless, I am unashamedly dependent on it and would encourage anyone to give it a try before removing all the logger code that I've written. [Installation is simple and the documentation is thorough.](https://github.com/OraOpenSource/Logger)

# Install this git repo

There is not much to be installed just 1 package, 6 types and 3 tables.

# Using the MailChimp API through PL/SQL
## Create a MailChimp account
Your 1st step should be to create a free account on [Mailchimp](https://mailchimp.com/).
### Get your API Key
You can create and manage your API keys in the account section of MailChimp.
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/api_key.png" alt="MailChimp API Keys" width="600">
      <br>
      <br>
</h1>
API keys are sensitive data. Keep yours secure, the one featured in the picture above is no longer a valid one.
### Determine your URL Prefix
You'll need to determine your 'URL prefix', as I'm calling it, to use the MailChimp API. You are assigned one when you create an account. I know that I'm 'us18' looking at the URL of MailChimp as a logged-in user. There are probably many ways to determine this.

### Authenticate your email with MailChimp
While you're there, be sure to authenticate the email you intend to have as your 'From' email with MailChimp:
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/authenticate_email.png" alt="Authenticate your email" width="600">
      <br>
      <br>
</h1>

### Populate values in package


With your URL prefix and API key, you can now begin populating the global variables listed at the top of the [blog_mailchimp_pkg body](source/packages/mailchimp_pkg.pkb).
```
g_url_prefix    constant varchar2(100):= 'https://usXX.api.mailchimp.com/3.0/';
g_company_name  constant varchar2(100):= '[Your organization]'; 
g_reply_to      constant varchar2(100):= '[The email you athenticated with MailChimp]'; 
g_from_name     constant varchar2(100):= '[Your name]';
g_password      constant varchar2(50) := '[your MailChimp API Key]';
g_wallet_path   constant varchar2(100):= 'file:[path to your Oracle Wallet]';
g_https_host    constant varchar2(100):= 'wildcardsan2.mailchimp.com';
```


## Create an email list
```
declare
l_list_id varchar2(100);
begin
  blog_mailchimp_pkg.create_list( p_list_name           => 'Blog subscribers',
                                  p_permission_reminder => 'You signed up for this email list.',
                                  p_list_id             => l_list_id);
                                
  dbms_output.put_line('Your newly generated list_id is  :'||l_list_id);
end;
```
### Add subscribers
```
declare
l_success boolean;
begin
  blog_mailchimp_pkg.add_subscriber ( p_list_id => '[you list_id]',
                                      p_email   => 'hhudson@insum.ca',
                                      p_fname   => 'Hayden',
                                      p_lname   => 'Hudson',
                                      p_success => l_success);
  if l_success then
    dbms_output.put_line('The operation was successful.');
  else
     dbms_output.put_line('Something went wrong. Check the logs.');
  end if;
end;
```
### View your subscribers
```
SELECT * 
FROM TABLE(FUNCTION get_list_of_subscribers ( p_list_id => '[you list_id]'));
```
## Prepare your email
## Create an email template
### Option 1: Create template with MailChimp GUI
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/template_gui.png" alt="MailChimp GUI" width="600">
      <br>
      <br>
</h1>

### Option 2: Create template with API
```
declare
l_template_id integer;
begin
   blog_mailchimp_pkg.create_template (p_template_name => 'My template name',
                                       p_html          => '<html><body>This is a really basic email.</body></html>',
                                       p_template_id   => l_template_id);
   dbms_output.put_line('Your newly generated template_id is  :'||l_template_id);
end;
```
## Pass data into your template with API
### Option 1: Update entire template html
```
declare
l_success boolean;
begin
   blog_mailchimp_pkg.update_template (p_template_id => '[you template_id]',
                                       p_html        => '<html><body>This is nothing fancy.</body></html>',
                                       p_success     => l_success);
   if l_success then
     dbms_output.put_line('The operation was successful.');
   else
     dbms_output.put_line('Something went wrong. Check the logs.');
   end if;
end;
```
### Option 2: Use Merge Fields

#### Add Merge Field(s) to your template

<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/template_substitutions.png" alt="Template Merge Fields" width="600">
      <br>
      <br>
</h1>

#### Add Merge Field(s) to your list
```
declare
l_merge_id integer;
l_tag      varchar2(100);
begin
   blog_mailchimp_pkg.create_merge_field( p_list_id          => '[you list_id]',
                                          p_merge_field_tag  => '[a tag for your merge field]',
                                          p_merge_field_name => '[a more descriptive name]'
                                          p_merge_id         => l_merge_id,
                                          p_tag              => l_tag);
   dbms_output.put_line('Your newly generated merge_id :'||l_merge_id);
   dbms_output.put_line('The associated tag is :'||l_tag);
end;
```
Note: Tags cannot be more than 10 characters. Must be unique within a given list. For the purposes of my example, the values that I’d pass into p_merge_field_tag are POST_NAME, COMMENT AND BLOGLINK (see template picture).
#### Assign value(s) to your Merge Field(s)
```
declare
l_success boolean;
begin
   blog_mailchimp_pkg.update_merge_field (p_list_id         => '[you list_id]',
                                          p_merge_field_tag => '[the tag for your merge field]',
                                          p_merge_value     => 'Nice post!',
                                          p_success         => l_success);
   if l_success then
     dbms_output.put_line('The operation was successful.');
   else
     dbms_output.put_line('Something went wrong. Check the logs.');
   end if;
end;
```
#### Review Merge Fields
```
SELECT *
FROM TABLE(blog_mailchimp_pkg.get_list_of_merge_fields(p_list_id => '[you list_id]'));
```
## Send your email
### Generate campaign url
```
declare
l_send_url varchar2(100);
begin
   blog_mailchimp_pkg.create_campaign ( p_list_id      =>'[you list_id]',
                                        p_subject_line => 'New blog comment',
                                        p_title        => 'Blog comment email',
                                        p_template_id  => '[you template_id]',
                                        p_send_url     => l_send_url);
   dbms_output.put_line('Your email is ready to send with the following url :'l_send_url);
end;
```
### Send campaign
```
declare
l_success boolean;
begin
   blog_mailchimp_pkg.send_campaign (p_send_url => '[your campaign send_url]',
                                     p_success  => l_success);
   if l_success then
     dbms_output.put_line('The operation was successful.');
   else
     dbms_output.put_line('Something went wrong. Check the logs.');
   end if;
end;
```
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/final_email.png" alt="Final Email" width="600">
      <br>
      <br>
</h1>


