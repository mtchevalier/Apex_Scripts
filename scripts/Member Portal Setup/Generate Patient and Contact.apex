//VARS TO SET START
String ENT_ACC_NAME = '';
String DOB = '01/01/2001';
//VARS TO SET STOP

public class NonUniqueEntAccountException extends Exception{}

List<Account> entAccs = [SELECT Id FROM Account WHERE Name = :ENT_ACC_NAME];
if(entAccs.size() == 0) {
    String res = '\n\n---->FAILURE<----\n'+
            'NO ACCOUNTS WITH THAT NAME\n';
    throw new NonUniqueEntAccountException(res);
} else if(entAccs.size() > 1) {
    String res = '---->FAILURE<----\n'+
            'MULTIPLE ACCOUNTS WITH THAT NAME\n';
    throw new NonUniqueEntAccountException(res);
} else {
    Id entAccId = entAccs[0].Id;

    Id entPatientRecTypeId = Schema.SObjectType.Patient__c.getRecordTypeInfosByName().get('Enterprise').getRecordTypeId();

    String phone = '1234567890';
    String email = ENT_ACC_NAME.deleteWhitespace()+'.Progyny@test.com';

    Patient__c ptnt = new Patient__c(
            Gender__c = 'F',
            Phone__c = phone,
            Email__c = email,
            LastName__c = 'Progyny',
            DateOfBirth_Text__c = DOB,
            Date_of_Birth__c = Date.parse(DOB),
            FirstName__c = ENT_ACC_NAME,
            Address__c = '111 hello ave.',
            City__c = 'New York',
            State_Province__c = 'NY',
            PostalCode__c = '111111',
            Enterprise_Account__c = entAccId,
            RecordTypeId = entPatientRecTypeId,
            Relation_to_Primary_Subscriber__c = 'Self'
    );

    insert ptnt;

    Id portalUserContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Portal User').getRecordTypeId();

    Contact con = new Contact(
            Email = email,
            Phone = phone,
            AccountId = entAccId,
            LastName = 'Progyny',
            Patient__c = ptnt.Id,
            FirstName = ENT_ACC_NAME,
            RecordTypeId = portalUserContactRecTypeId
    );

    insert con;
    ptnt.Patient_Contact__c = con.Id;
    update ptnt;

    System.debug('Patient Id:');
    System.debug(ptnt.Id);

    System.debug('Contact Id:');
    System.debug(con.Id);
}









