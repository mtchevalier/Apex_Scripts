Boolean allowRunInProduction = false;
//Boolean allowRunInProduction = true;
Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

if(isSandbox || allowRunInProduction) {
    Id batchJobId = Database.executeBatch(new ProgynyAxleEmailsBatchable(), 150);
} else {
    System.debug('PRODUCTION ENVIRONMENT!!!');
}