# ORA-29024: Certificate of the remote server does not match the target address

Does your apex_web_service.make_rest_request generate the following error? 
```
ORA-24263: Certificate of the remote server does not match the target address.
```
This error must be because you are on a 12.2 or higher database and you need to an ['HTTPS_HOST' parameter to your request](http://www.orafaq.com/node/3079). For example:
```
select apex_web_service.make_rest_request(
      p_url         => 'https://us18.api.mailchimp.com'
    , p_http_method => 'GET' 
    , p_wallet_path => 'file:/home/oracle/orapki_wallet' 
    , p_https_host  => 'wildcardsan2.mailchimp.com'
    ) from dual;
```
Notice how different the p_url is from the p_https_host? This shows that MailChimp is using a 'multiple domain certificate'. Such a certificate now needs special handling in an Oracle environment.

## How to identify the https_host

### Visit a URL for your API
 
I recommend using Firefox for its ease-of-use. For this example, I visited https://us18.api.mailchimp.com/3.0/:
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/get_certificates1.png" alt="Visit website in Firefox" width="600">
      <br>
      <br>
</h1>

### Click on the 'information' icon in the URL bar
Then click on the right-arrow to access 'More information'.
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/get_certificates2.png" alt="Click on information icon" width="600">
      <br>
      <br>
</h1>

### Visit the 'Security' tab
Click on 'View Certificate'
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/get_certificates3.png" alt="Navigate to security tab" width="600">
      <br>
      <br>
</h1>

### Find the Common Name
You can view the 'Common Name' under the 'General' tab:
<h1 align="center">
      <br>
      <img src="https://raw.githubusercontent.com/hhudson/mailchimp_plsql_api/master/docs/img/id_common_name.png" alt="Identify website common name" width="600">
      <br>
      <br>
</h1>
This 'Common Name' is your 'https host'.