List<String> stateAbbrvs = 'CA,WA,NY,TX,NJ,PA,IL,FL,GA,NC,VA,CO,MN,MD,TN,AZ,OH,MO,OR,DC,UT,NV,NE,KY,ME,DE,AL,OK,NH'.split(',');
List<Id> entAccIds = '0014000001gWBhwAAG,0011W00001tJTcyQAG,0014000001e2QsjAAE,0011W00001tuAb2QAE,0014000001n2CoCAAU,0014000001qUwP5AAK'.split(',');

List<AggregateResult> count = [SELECT  COUNT_DISTINCT(Patient__c)
FROM Authorization__c
WHERE CALENDAR_YEAR(Start_Date__c) = 2022
AND Auth_Type__c = 'Medical'
AND Patient__r.Email__c != NULL
AND Patient__r.State_Province__c IN :stateAbbrvs
AND Patient__r.Enterprise_Account__c IN :entAccIds
AND CreatedDate < :Date.newInstance(2022, 03, 08)
];

System.debug('MATDEV count:');
System.debug(count);