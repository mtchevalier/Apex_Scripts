String OBJECT_API_NAME = 'Authorization__c' ;
String FIELD_API_NAME = 'Latest_Recycle_User__c';
Map<String, String> PROFILE_TO_ACCESS = 
        new Map<String, String>{
                'System Administrator' => 'U'
        };

List<PermissionSet> permissionSets = [
        SELECT  Profile.Name,
        (
                SELECT  SobjectType,
                        Field,
                        PermissionsRead,
                        PermissionsEdit
                FROM FieldPerms
                WHERE SobjectType = :OBJECT_API_NAME
                AND Field = :OBJECT_API_NAME+'.'+FIELD_API_NAME
        )
        FROM PermissionSet
        WHERE IsOwnedByProfile = TRUE
];

Map<String, PermissionSet> profileNameToPermSet = new Map<String, PermissionSet>();
for(PermissionSet pSet : permissionSets) {
    String profileName = pSet.Profile.Name;
    if(PROFILE_TO_ACCESS.containsKey(profileName)) {
        profileNameToPermSet.put(profileName, pSet);
    }
}

List<FieldPermissions> fpsToUpdate = new List<FieldPermissions>();

for(String profileName : profileNameToPermSet.keySet()) {
    PermissionSet pSet = profileNameToPermSet.get(profileName);
    String crud = PROFILE_TO_ACCESS.get(profileName);
    
    if(pSet.FieldPerms.size() == 1) {
        FieldPermissions fp = pSet.FieldPerms[0];
        fp.PermissionsRead = crud.contains('R') || crud.contains('U');
        fp.PermissionsEdit = crud.contains('U');
        fpsToUpdate.add(fp);
    } else {
        fpsToUpdate.add(
                new FieldPermissions(
                        ParentId = pSet.Id,
                        SobjectType = OBJECT_API_NAME,
                        Field = OBJECT_API_NAME+'.'+FIELD_API_NAME,
                        PermissionsRead = crud.contains('R') || crud.contains('U'),
                        PermissionsEdit = crud.contains('U')
                )
        );
    }
}

if(!fpsToUpdate.isEmpty()) {
    upsert fpsToUpdate;
}





