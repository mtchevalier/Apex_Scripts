// TESTING CONFIGURATIONS START
Boolean IS_TEST = true;
String TEST_RECIPIENT_EMAIL = 'wacook3@gmail.com';
//String TEST_RECIPIENT_EMAIL = 'brancoofpa@gmail.com';
// TESTING CONFIGURATIONS STOP

// CONFIGURATIONS START
Boolean SEND_SECURE = false;
Boolean OMIT_WHEN_SC_BAL_EXHAUSTED = true;

String EMAIL_SUBJECT = 'A Message from Progyny!';
String ORG_WIDE_EMAIL_ADDRESS = 'pcas@progyny.com';
String CLIENT_ENT_ACCOUNT_ID = '0014000001qWsgXAAS';

Map<String, String> MERGE_TEXT_TO_FIELD = new Map<String, String>{
        '{MEMBER_FIRST_NAME}' => 'FirstName__c'
};
String PLAIN_TEXT_BODY = 'Dear {MEMBER_FIRST_NAME},\n\nWe are writing to let you know that M&T Bank has generously expanded its fertility benefit for 2022 to include an integrated medication experience through Progyny Rx.\n\nAll standard of care fertility medications needed for your treatment will be included in your Smart Cycle benefit. Progyny Rx includes a seamless authorization process, overnight delivery of your medications and access to pharmacy clinicians to answer your questions and support you. See your member guide attached for the Progyny Rx formulary of covered medications and a helpful Progyny Rx FAQ section.\n\nPlease note that you must be enrolled in an eligible medical plan to access these fertility benefits.  Don’t hesitate to reach out to your PCA at (833) 272-1069 if you have any questions. If you have immediate plans for a treatment cycle, please reach out to your PCA at your soonest convenience.\n\nBest,\nYour Progyny Family';
// CONFIGURATIONS STOP

Map<Id, Map<String, Benefit_Order__c>> entAccIdToYearToBO = ProgynyBenefitOrderFetcher.getEnterpriseAccountIdToYearToBenefitOrder(new Set<Id>{CLIENT_ENT_ACCOUNT_ID});

Benefit_Order__c bo = entAccIdToYearToBO.get(CLIENT_ENT_ACCOUNT_ID).get('2022');

ProgynyContentVersionUtility.Config config = new ProgynyContentVersionUtility.Config();
config.linkedEntityIds = new List<Id>{bo.Id};
config.fuzzyTitleSearch = false;
config.includeVersionData = true;

List<ContentVersion> onboardingDocs = ProgynyContentVersionUtility.getLinkedEntityIdToLatestVersionDocuments(config).get(bo.Id);

ContentVersion memberGuide;

for(ContentVersion conVer : onboardingDocs) {
    if(conVer.Title.contains('Member Guide')) {
        memberGuide = conVer;
    }
}

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
    em.setEntityAttachments(new List<String>{memberGuide.Id});

    String body = PLAIN_TEXT_BODY;
    for(String mergeText : MERGE_TEXT_TO_FIELD.keySet()) {
        body = body.replace(mergeText, (String)ptnt.get(MERGE_TEXT_TO_FIELD.get(mergeText)));
    }
    em.setPlainTextBody(body);
    emails.add(em);
    ptnt.put('EOY_Email_Blast_Sent_'+today.year()+'__c', today);
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

ProgynyStaticFuture.executePatientTrgAfter = false;
ProgynyStaticFuture.executePatientTrg = false;
update patientsToUpdate;