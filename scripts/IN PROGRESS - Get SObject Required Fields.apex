// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

Schema.DescribeSObjectResult r = Account.sObjectType.getDescribe();
Map<String,Schema.SObjectField> M = r.fields.getMap();

System.debug('Required Custom fields-->(label: apiName)');
for(String fieldName : M.keySet()){
    Schema.SObjectField field = M.get(fieldName);
    Schema.DescribeFieldResult F = field.getDescribe();
    //A nillable field can have empty content. A isNillable Boolean non-nillable field must have a value for the object to be                       
    //created or saved. 
    // if F.isNillable() is false then field is mandatory
    if(!F.isNillable() && F.isCustom()){
        System.debug (F.getLabel() +': ' + field );
    }
}
List<ValidationRule> validationRules = [
        SELECT Id, ValidationName, Active, Description, EntityDefinition.DeveloperName, ErrorDisplayField, ErrorMessage
        FROM ValidationRule
        WHERE Active = true
        AND EntityDefinition.DeveloperName = 'Account'
]

ValidationRule vRule = [SELECT ValidationName, Description, ErrorMessage, Metadata
FROM ValidationRule
WHERE Active = true
AND EntityDefinition.DeveloperName = 'Account'
LIMIT 1];

System.debug('MATDEV');
System.debug(Metadata.errorConditionFormula);