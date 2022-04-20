//VARS TO SET START
Id ENT_ACC_ID = '';
String BOF_YEAR = '2022';
//VARS TO SET STOP

public class MemberPortalAccessException extends Exception{}

Benefit_Order__c bof = [
        SELECT  Member_Portal__c,
                Happify_Access__c,
                Member_Portal_Access__c
        FROM Benefit_Order__c
        WHERE Account__c = :ENT_ACC_ID
        AND Plan_Year__c = :BOF_YEAR
];

if(bof.Member_Portal_Access__c == 'Yes') {
    if( (bof.Member_Portal__c == 'No') || (bof.Happify_Access__c == 'No') ) {
        bof.Member_Portal__c = 'Yes';
        bof.Happify_Access__c = 'Yes';
        update bof;
    }
} else {
    String res = '---->FAILURE<----\n'+
            'bof.Member_Portal_Access__c == "No"\n'+
            'contact Ankita and follow her instructions';
    throw new MemberPortalAccessException(res);
}
System.debug('BOF Id:');
System.debug(bof.Id);



