global with sharing  class EmailHelper {

    public static void sendEmail(Project__c proj, String error){
        // If we know how many addresses the email will be sent to from this transaction
        // We can set the reserve capacity
        system.debug('dentro de metodo sendEmail');
        system.debug(proj);
        Messaging.reserveSingleEmailCapacity(1);
     
        //We instantiate our single email message object
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
     
        // Strings to hold the email addresses to which you are sending the email.
        User pm = [SELECT Id,Email FROM USER WHERE Id=:proj.Project_Manager__c];
        String pmEMail = pm.Email;
        system.debug('pmEMail');
        system.debug(pmEMail);
        String[] toAddresses = new String[] {pmEMail};
        system.debug('to Addresses');
        system.debug(toAddresses);
        //Assign the TO address to our mail object
        mail.setToAddresses(toAddresses);
 
        //List of ccAddress
        //String[] ccAddresses = new String[] {'robin.lacruz@gmail.com'};
        // Assign the CC addresses
        //mail.setCcAddresses(ccAddresses);
 
        // Here we can set the address that will be used when a recipient replies to the email
       // mail.setReplyTo('');
 
        // Specify the name used as the display name.
        mail.setSenderDisplayName('El proyecto no puede iniciar');
 
        // Set the subject line for your email address.
        mail.setSubject('Accion necesaria del Project Manager');
 
        // You can set this to true if you want to BCC yourself on the email
        mail.setBccSender(false);
 
        // You can specify your plain text here
        mail.setPlainTextBody('Sample plain text goes here');
         String body = '<!doctypehtml><html lang=en xmlns:o=urn:schemas-microsoft-com:office:office xmlns:v=urn:schemas-microsoft-com:vml><title></title><meta content="text/html; charset=utf-8"http-equiv=Content-Type><meta content="width=device-width,initial-scale=1"name=viewport><!--[if mso]><xml><o:officedocumentsettings><o:pixelsperinch>96</o:pixelsperinch><o:allowpng></o:officedocumentsettings></xml><![endif]--><style>*{box-sizing:border-box}body{margin:0;padding:0}a[x-apple-data-detectors]{color:inherit!important;text-decoration:inherit!important}#MessageViewBody a{color:inherit;text-decoration:none}p{line-height:inherit}.desktop_hide,.desktop_hide table{mso-hide:all;display:none;max-height:0;overflow:hidden}@media (max-width:520px){.desktop_hide table.icons-inner{display:inline-block!important}.icons-inner{text-align:center}.icons-inner td{margin:0 auto}.row-content{width:100%!important}.column.border,.mobile_hide{display:none}table{table-layout:fixed!important}.stack .column{width:100%;display:block}.mobile_hide{min-height:0;max-height:0;max-width:0;overflow:hidden;font-size:0}.desktop_hide,.desktop_hide table{display:table!important;max-height:none!important}}</style><body style=background-color:#fff;margin:0;padding:0;-webkit-text-size-adjust:none;text-size-adjust:none><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;background-color:#fff width=100% border=0 class=nl-container><tr><td><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class="row row-1"align=center><tr><td><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;color:#000;width:500px width=500 border=0 class="row-content stack"align=center><tr><td style=mso-table-';
        String body2 = 'lspace:0;mso-table-rspace:0;font-weight:400;text-align:left;vertical-align:top;padding-top:5px;padding-bottom:5px;border-top:0;border-right:0;border-bottom:0;border-left:0 class="column column-1"width=100%><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=image_block><tr><td style=width:100%;padding-right:0;padding-left:0><div align=center style=line-height:10px><img src=https://upload.wikimedia.org/wikipedia/commons/thumb/f/f9/Salesforce.com_logo.svg/800px-Salesforce.com_logo.svg.png style=display:block;height:auto;border:0;width:100px;max-width:100% width=100></div></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=heading_block><tr><td style=width:100%;text-align:center><h1 style="margin:0;color:#555;font-size:23px;font-family:Arial,Helvetica Neue,Helvetica,sans-serif;line-height:120%;text-align:center;direction:ltr;font-weight:700;letter-spacing:normal;margin-top:0;margin-bottom:0"><span class=tinyMce-placeholder>Un proyecto requiere de tu atención</span></h1></table><table cellpadding=10 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=divider_block><tr><td><div align=center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-';
        String body3 = 'lspace:0;mso-table-rspace:0 width=100% border=0><tr><td style="font-size:1px;line-height:1px;border-top:1px solid #bbb"class=divider_inner><span> </span></table></div></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;word-break:break-word;word-wrap:break-word width=100% border=0 class=html_block><tr><td style=padding-top:60px><div align=center style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;text-align:center"><div class=our-class>';
        String body35 = '.</div></div></table><table cellpadding=10 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=divider_block><tr><td><div align=center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0><tr><td style="font-size:1px;line-height:1px;border-top:1px solid #bbb"class=divider_inner><span> </span></table></div></table></table></table><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class="row row-2"align=center><tr><td><table cellpadding=0 cellspacing=0';
        String body4= 'role=presentation style=mso-table-lspace:0;mso-table-rspace:0;color:#000;width:500px width=500 border=0 class="row-content stack"align=center><tr><td style=mso-table-lspace:0;mso-table-rspace:0;font-weight:400;text-align:left;vertical-align:top;padding-top:5px;padding-bottom:5px;border-top:0;border-right:0;border-bottom:0;border-left:0 class="column column-1"width=100%><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100% border=0 class=icons_block><tr><td style=vertical-align:middle;color:#9d9d9d;font-family:inherit;font-size:15px;padding-bottom:5px;padding-top:5px;text-align:center><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0 width=100%><tr><td style=vertical-align:middle;text-align:center><!--[if vml]><table cellpadding=0 cellspacing=0 role=presentation style=display:inline-block;padding-left:0;padding-';
        String body5= 'right:0;mso-table-lspace:0;mso-table-rspace:0 align=left><![endif]--><!--[if !vml]><!--><table cellpadding=0 cellspacing=0 role=presentation style=mso-table-lspace:0;mso-table-rspace:0;display:inline-block;margin-right:-4px;padding-left:0;padding-right:0 class=icons-inner><!--<![endif]--><tr><td style=vertical-align:middle;text-align:center;padding-top:5px;padding-bottom:5px;padding-left:5px;padding-right:6px>td style="font-family:Arial,Helvetica Neue,Helvetica,sans-serif;font-size:15px;color:#9d9d9d;vertical-align:middle;letter-spacing:undefined;text-align:center"><a href=https://www.designedwithbee.com/ style=color:#9d9d9d;text-decoration:none target=_blank></table></table></table></table></table></table>';
 
        //Specify any html - for example this will display
        String link = 'https://plataforma585-dev-ed.lightning.force.com/lightning/r/Project__c/'+proj.id+'/view';
        
        String linkDiv = '<a href= \'' + link + '\'> <h3>Click para ir al proyecto con problemas<h3></a>';
        String errorMessage = '<b>Motivo:</b> ' + error ;
        String contenido = '<b>El proyecto ' + proj.Name + ' no puede pasar a estado In Progress </b>' +'<br>'+errorMessage+'<br>'+linkDiv;
        
        
        body = body+body2+body3+contenido+body35+body4+body5;
        mail.setHtmlBody(body);
        system.debug('body');
        system.debug(body);
        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
 }