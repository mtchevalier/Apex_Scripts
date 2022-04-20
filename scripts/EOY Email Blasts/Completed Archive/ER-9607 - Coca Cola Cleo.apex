// TESTING CONFIGURATIONS START
Boolean IS_TEST = false;
//String TEST_RECIPIENT_EMAIL = 'wacook3@gmail.com';
//String TEST_RECIPIENT_EMAIL = 'priyavmehta6@gmail.com';
String TEST_RECIPIENT_EMAIL = 'priya.mehta@progyny.com';
//String TEST_RECIPIENT_EMAIL = 'brancoofpa@gmail.com';
//String TEST_RECIPIENT_EMAIL = 'matthew.chevalier@progyny.com';
// TESTING CONFIGURATIONS STOP

// CONFIGURATIONS START
Boolean SEND_SECURE = false;
Boolean OMIT_WHEN_SC_BAL_EXHAUSTED = false;

String EMAIL_SUBJECT = 'A Message from Progyny!';
String ORG_WIDE_EMAIL_ADDRESS = 'pcas@progyny.com';
String CLIENT_ENT_ACCOUNT_ID = '0014000001e2QsHAAU';

Map<String, String> MERGE_TEXT_TO_FIELD = new Map<String, String>{
        '{First Name}' => 'FirstName__c'
};
String PLAIN_TEXT_BODY = 'Hi {First Name},<br/>' +
        '<br/>' +
        'Did you know that in addition to Progyny, you also have access to personalized family planning guidance from Cleo through your TCCC employee benefits? With Cleo, you gain access not only to a comprehensive library of resources, articles, and tips related to growing your family, you’re also paired with a 1:1 dedicated Cleo Guide, a family planning expert, who is there to provide continuous support throughout your journey and beyond. <br/>' +
        '<br/>' +
        'You’ll receive personalized support from your Guide through planning and attempts to expand your family, whether that be tracking your fertility, exploring IVF, IUI, surrogacy, adoption, fostering, or recovering from a loss - helping to provide emotional wellness and how to best stay in sync on decision making and more. Cleo stays with you as well once you’re expecting through the birth of your child and beyond, providing expert guidance in areas like preparing for the birth of your child, sleep training, feeding, and more. Cleo supports all types of families, from birthing parents, supportive partners, adoptive and surrogate parents, same-sex parents, foster parents, and solo parents. <br/>' +
        '<br/>' +
        'To access your Cleo benefit, simply <a href="https://link.hicleo.com/byCJUsa15gb">click here</a> and use code TCCC to enroll for free. Visit <a href="https://hicleo.com/for-families/">Cleo</a>  to learn more about your free family-focused employee benefit.<br/>' +
        '<br/>' +
        'Sincerely, <br/>' +
        'Your Progyny Family';
// CONFIGURATIONS STOP

public class ConfigIncompleteException extends Exception{}
if(
        String.isBlank(CLIENT_ENT_ACCOUNT_ID)
                || String.isBlank(EMAIL_SUBJECT)
                || String.isBlank(ORG_WIDE_EMAIL_ADDRESS)
                || String.isBlank(PLAIN_TEXT_BODY)
        ) {
    throw new ConfigIncompleteException('Ensure all Configurations are populated');
}

String recipientsQuery =
        'SELECT  Email__c, '+
                'FirstName__c, '+
                'Preferred_Name__c '+
                'FROM Patient__c '+
                'WHERE Enterprise_Account__c = \''+CLIENT_ENT_ACCOUNT_ID+'\' '+
                'AND Email__c != NULL '+
                'AND Eligibility_Status__c = \'Active\' '+
                'AND RecordType.Name = \'Enterprise\' '+
                (OMIT_WHEN_SC_BAL_EXHAUSTED ? 'AND SMART_Cycle_Balance__c > 0 ' : '')+
                (IS_TEST ? 'LIMIT 1' : '');

List<Patient__c> membersToReceiveEmailBlast = Database.query(recipientsQuery);
System.debug('recipientsQuery:');
System.debug(recipientsQuery);

List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
List<Patient__c> patientsToUpdate = new List<Patient__c>();

OrgWideEmailAddress OWEA = ProgynyEmailUtility.getOrgWideEmailAddress(ORG_WIDE_EMAIL_ADDRESS);
Date today = Date.today();

for(Patient__c ptnt : membersToReceiveEmailBlast) {
    Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
    em.setSubject((SEND_SECURE ? 'SECURE: ' : '') + EMAIL_SUBJECT);
    em.setSaveAsActivity(false);
    if(IS_TEST) {
        em.setToAddresses(new String[]{TEST_RECIPIENT_EMAIL});
    } else {
        em.setToAddresses(new String[]{ptnt.Email__c});
    }
    em.setBccAddresses(new String[]{'progynybcc@progyny.com'});
    em.setOrgWideEmailAddressId(OWEA.Id);

    String body = PLAIN_TEXT_BODY;
    for(String mergeText : MERGE_TEXT_TO_FIELD.keySet()) {
        body = body.replace(mergeText, (String)ptnt.get(MERGE_TEXT_TO_FIELD.get(mergeText)));
    }
//    em.setPlainTextBody(body);
    em.setHtmlBody(body);
    emails.add(em);
//    ptnt.put('EOY_Email_Blast_Sent_'+today.year()+'__c', today);
    ptnt.put('EOY_Email_Blast_Sent_2021__c', today);
    patientsToUpdate.add(ptnt);
}
Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
Boolean noErrors = true;
for(Messaging.SendEmailResult res : results) {
    if (!res.isSuccess()) {
        noErrors = false;
    }
}
if(noErrors) {
    System.debug('SUCCESS!');
} else {
    System.debug('FAILED SendEmailResults BELOW:');
    for(Messaging.SendEmailResult res : results) {
        if(!res.isSuccess()) {
            noErrors = false;
            for(Messaging.SendEmailError error : res.getErrors()) {
                System.debug('error.getMessage():');
                System.debug(error.getMessage());
                System.debug('error.getFields():');
                System.debug(error.getFields());
                System.debug('error.getStatusCode():');
                System.debug(error.getStatusCode());
                System.debug('error.getTargetObjectId():');
                System.debug(error.getTargetObjectId());
            }
        }
    }
}

if(!IS_TEST) {
    ProgynyStaticFuture.executePatientTrgAfter = false;
    ProgynyStaticFuture.executePatientTrg = false;
    update patientsToUpdate;
}