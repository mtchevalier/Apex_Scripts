String OBJECT_API = 'Patient__c';
String FIELD_API = 'ESI_Member_ID__c';

List<PermissionSet> pSets = [
        SELECT  Name,
                Profile.Name,
                IsOwnedByProfile,
        (
                SELECT  PermissionsRead,
                        PermissionsEdit
                FROM FieldPerms
                WHERE SobjectType = :OBJECT_API
                AND Field = :OBJECT_API+'.'+FIELD_API
        )
        FROM PermissionSet
        ORDER BY Profile.Name ASC
];

Map<String, String> pSetToAccess = new Map<String, String>();

Map<String, String> profileToAccess = new Map<String, String>();

String access;
for(PermissionSet pSet : pSets) {
    if(!pSet.FieldPerms.isEmpty()) {
        access = null;
        FieldPermissions fieldPerm = pSet.FieldPerms[0];
        if(fieldPerm.PermissionsEdit) {
            access = 'R/W';
        } else if(fieldPerm.PermissionsRead) {
            access = 'R';
        }
        if(!String.isBlank(access)) {
            if(pSet.IsOwnedByProfile) {
                profileToAccess.put(pSet.Profile.Name, access);
            } else {
                pSetToAccess.put(pSet.Name, access);
            }
        }
    }
}

System.debug('\nPERMISSION SET ACCESS:');
for(String pSet : pSetToAccess.keySet()) {
    System.debug(pSet+': '+pSetToAccess.get(pSet));
}
System.debug('\nPROFILE ACCESS:');
for(String profile : profileToAccess.keySet()) {
    System.debug(profile+': '+profileToAccess.get(profile));
}