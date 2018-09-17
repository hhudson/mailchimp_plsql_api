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
If you get the error 'ORA-29024: Certificate validation failure', it must be because you have not imported the certificate chain referenced above to your linked oracle wallet. For greater details on how I configured my Oracle Wallet : 

If you get the error 'ORA-24263: Certificate of the remote server does not match the target address.', it must mean that you are on a 12.2 database (or higher) and you need to add a parameter to your request:
```
select apex_web_service.make_rest_request(
      p_url         => 'https://us18.api.mailchimp.com'
    , p_http_method => 'GET' 
    , p_wallet_path => 'file:/home/oracle/orapki_wallet_nowc' 
    , p_https_host  => 'wildcardsan2.mailchimp.com'
    ) from dual;
```
The 'HTTPS Host' refers to 'Common Name' of the URL you are trying to reach and must now be specified when it does not match the destination URL. For more details on this error : 

## Install Logger

It would of course be perfectly possible to write this PL/SQL package without reference to Logger. Nonetheless, I am unashamedly dependent on it and would encourage anyone to give it a try before removing all the logger code that I've written. [Installation is simple and the documentation is thorough.](https://github.com/OraOpenSource/Logger)

# Install this repo

There is not much to be installed just 1 package, some types and tables.

# Using the MailChimp API through PL/SQL
## Create a MailChimp account
Your 1st step should be to create a free account on [Mailchimp](https://mailchimp.com/)
### Get your API Key
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/OraOpenSource/apex-nitro/master/docs/img/apex-nitro-logo.png" alt="APEX Nitro" width="600">
      <br>
      <br>
</h1>
### Determine your URL Prefix
### Populate values in package
### Authenticate your email with MailChimp
## Create an email list
### Add subscribers
### View your subscribers
## Prepare your email
## Create an email template
### Option 1: Create template with MailChimp GUI
### Option 2: Create template with API
## Pass data into your template with API
### Option 1: Update entire template html
### Option 2: Use Merge Fields
#### Add Merge Field to your template
#### Add Merge Field to your list
#### Assign value to Merge Field
#### Review Merge Fields
## Send your email
### Generate campaign url
### Send campaign


