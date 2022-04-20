String emailAddress = 'brancoofpa@gmail.com';

List<Patient__c> ptnts = [
    SELECT Id, Email__c, Phone__c, Other_Phone__c
    FROM Patient__c
    WHERE Email__c = :emailAddress
];

for(Patient__c ptnt : ptnts) {
    ptnt.Email__c = null;
    ptnt.Phone__c = null;
    ptnt.Other_Phone__c = null;
}

//Boolean allowRunInProduction = true;
Boolean allowRunInProduction = false;
Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

if(isSandbox || allowRunInProduction) {
    update ptnts;
} else {
    System.debug('PRODUCTION ENVIRONMENT!!!');
}

