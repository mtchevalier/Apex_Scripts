// TESTING CONFIGURATIONS START
Boolean IS_TEST = true;
//String TEST_RECIPIENT_EMAIL = 'wacook3@gmail.com';
//String TEST_RECIPIENT_EMAIL = 'priyavmehta6@gmail.com';
String TEST_RECIPIENT_EMAIL = 'brancoofpa@gmail.com';
// TESTING CONFIGURATIONS STOP

// CONFIGURATIONS START
Boolean SEND_SECURE = false;
Boolean OMIT_WHEN_SC_BAL_EXHAUSTED = false;

String EMAIL_SUBJECT = 'A Message from Progyny!';
String ORG_WIDE_EMAIL_ADDRESS = 'pcas@progyny.com';
String CLIENT_ENT_ACCOUNT_ID = '0011W00002Qi1GkQAJ';

Map<String, String> MERGE_TEXT_TO_FIELD = new Map<String, String>{
        '{MEMBER_FIRST_NAME}' => 'FirstName__c'
};
String PLAIN_TEXT_BODY = 'Dear {MEMBER_FIRST_NAME},\n' +
        '\n' +
        'Greetings from Progyny! We are writing to let you know that Joby Aviation has generously enhanced its fertility benefit to include reimbursement coverage for Surrogacy services. Effective 1/1/2022, the lifetime maximum for both the adoption and surrogacy programs will be $25,000.\n' +
        '\n' +
        'Please reach out to your dedicated PCA at 844-930-3350 to learn more about your Progyny fertility benefit and how this benefit enhancement impacts you. We look forward to hearing from you!\n' +
        '\n' +
        'Sincerely,\n' +
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
    em.setPlainTextBody(body);
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