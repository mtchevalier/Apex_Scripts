Progyny_Connect_Configuration__mdt config = [SELECT  Eligible_State_Abbreviations__c,Eligible_Enterprise_Account_Ids__c FROM Progyny_Connect_Configuration__mdt WHERE DeveloperName = 'Master'];
List<String> stateAbbrvs = config.Eligible_State_Abbreviations__c.split(',');
List<Id> entAccIds = config.Eligible_Enterprise_Account_Ids__c.split(',');
OrgWideEmailAddress pcasOWEA = ProgynyEmailUtility.getOrgWideEmailAddress('pcas@progyny.com');
EmailTemplate emailTemplate = ProgynyEmailUtility.getEmailTemplateFromDeveloperName('ProgynyConnectInvitation');
Id attachmentId = ProgynyEmailUtility.getEmailTemplateRelatedDocuments(emailTemplate)[0].Id;
List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
List<Patient__c> patientsToUpdate = new List<Patient__c>();

for(Patient__c ptnt : getBlast1Patients()) {
    if((!ptnt.Authorizations__r.isEmpty()) && (!ptnt.Carriers__r.isEmpty())) {
        emails.add(generateEmail(ptnt.Email__c));
        patientsToUpdate.add(new Patient__c(Id=ptnt.Id, Progyny_Connect_Invite_Sent__c=true));
    }
}

ProgynyStaticFuture.executePatientTrgAfter = false;
ProgynyStaticFuture.executePatientTrg = false;
System.debug('MATDEV patientsToUpdate.size():');
System.debug(patientsToUpdate.size());
update patientsToUpdate;

Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
System.debug('MATDEV Email results.size():');
System.debug(results.size());
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
        debugEmailSendErrors(res);
    }
}

/*
methods
* */

List<Patient__c> getBlast1Patients() {
    return [
            SELECT Email__c,
            (
                    SELECT Id
                    FROM Authorizations__r
                    WHERE Start_Date__c >= 2021-10-01
                    AND Start_Date__c <= 2021-12-31
            ),
            (
                    SELECT Id
                    FROM Carriers__r
                    WHERE Plan_Year__c = '2022'
            )
            FROM Patient__c
            WHERE Member_Eligibility_Status__c LIKE 'Active Coverage%'
            AND Progyny_Connect_Invite_Sent__c = FALSE
            AND RecordType.Name = 'Enterprise'
            AND State_Province__c IN :stateAbbrvs
            AND Enterprise_Account__c IN :entAccIds
            AND Email__c != NULL
            LIMIT 200
    ];
}

Messaging.SingleEmailMessage generateEmail(String patientEmail){
    Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();

    em.subject = emailTemplate.Subject;
    em.htmlBody = emailTemplate.HtmlValue;
    em.plainTextBody = emailTemplate.Body;
    em.saveAsActivity = false;
    em.orgWideEmailAddressId = pcasOWEA.Id;
    em.toAddresses = new List<String>{patientEmail};
    em.bccAddresses = new List<String> {'progynybcc@progyny.com'};
    em.setEntityAttachments(new List<Id>{attachmentId});
    return em;
}

void debugEmailSendErrors(Messaging.SendEmailResult res) {
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

