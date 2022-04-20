Boolean IS_TEST = true;
String OBJECT_API_NAME = 'Account';
String PAGE_LAYOUT_NAME = 'Enterprise Account Layout';

Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
for(Schema.SObjectType sObj : globalDescribe.values()) {
    Schema.DescribeSObjectResult dsr = sObj.getDescribe();
    
}

List<Metadata.Metadata> layouts =
        Metadata.Operations.retrieve(Metadata.MetadataType.Layout,
                new List<String> {OBJECT_API_NAME+'-'+PAGE_LAYOUT_NAME});

Metadata.DeployContainer deployContainer = new Metadata.DeployContainer();

for(Metadata.Metadata layout : layouts) {
    if(removeLogACallButton((Metadata.Layout)layout)) {
        deployContainer.addMetadata(layout);
    }
}

if(!IS_TEST) {
    Id jobId = Metadata.Operations.enqueueDeployment(deployContainer, null);
}

/*
    METHODS
*/
Boolean removeLogACallButton(Metadata.Layout layout) {
    List<Metadata.PlatformActionListItem> actions = layout.platformActionList.platformActionListItems;
    for(Integer i=0; i<actions.size(); i++) {
        if(actions[i].actionName == 'LogACall') {
            actions.remove(i);
            return true;
        }
    }
    return false;
}