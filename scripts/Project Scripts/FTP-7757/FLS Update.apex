String OBJECT_API_NAME = 'Patient__c' ;

//String FIELD_API_NAME = 'Manager_Smart_Cycle_Exceptions__c';
//String FIELD_API_NAME = 'Manager_Smart_Cycle_Exception_Notes__c';

Map<String, String> PROFILE_TO_ACCESS =
        new Map<String, String>{
                'System Administrator' => 'RU',
                'Customer Community Login - Member' => 'R',
                'Progyny API User Cognos' => 'R',
                'Progyny API User Email Context' => 'R',
                'Progyny API User Five9' => 'R',
                'Progyny API User Happify' => 'R',
                'Progyny API User Incontact' => 'R',
                'Progyny API User Internal' => 'R',
                'Progyny API User Marketing Cloud' => 'R',
                'Progyny Account Management' => 'R',
                'Progyny Analytics' => 'R',
                'Progyny Employee PCA' => 'R',
                'Progyny Engineering' => 'R',
                'Progyny Finance' => 'R',
                'Progyny Implementation' => 'R',
                'Progyny Medical Advisor Board' => 'R',
                'Progyny Networking' => 'R',
                'Progyny Patient Care Advocate' => 'R',
                'Progyny Project Management' => 'R',
                'Progyny Provider Relation' => 'R',
                'Progyny Provider Relations Manager' => 'R'
        };

public class ConfigIncompleteException extends Exception{}
if(
        String.isBlank(OBJECT_API_NAME)
                || String.isBlank(FIELD_API_NAME)
                || PROFILE_TO_ACCESS.isEmpty()
) {
    throw new ConfigIncompleteException('Ensure all Configurations are populated');
}

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