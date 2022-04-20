Set<String> targetAssigneeNames = new Set<String>{'Justin Alvis', 'Edward Hsyeh', 'Lissa Kline'};
List<PermissionSetAssignment> psas = [
        SELECT  PermissionSet.Name,
                Assignee.Name
        FROM PermissionSetAssignment
];

System.debug('PSAs total:');
System.debug(psas.size());

Set<String> nonExclusivePermSetNames = new Set<String>();

Map<String, Integer> permSetNameToTotalTargetAssignees = new Map<String, Integer>();

for(PermissionSetAssignment psa : psas) {
    String permSetName = psa.PermissionSet.Name;
    if(!nonExclusivePermSetNames.contains(permSetName)) {
        if(!targetAssigneeNames.contains(psa.Assignee.Name)) {
            nonExclusivePermSetNames.add(permSetName);
        } else {
            if(permSetNameToTotalTargetAssignees.containsKey(permSetName)) {
                Integer total = permSetNameToTotalTargetAssignees.get(permSetName);
                total++;
                permSetNameToTotalTargetAssignees.put(permSetName, total);
            } else {
                permSetNameToTotalTargetAssignees.put(permSetName, 1);
            }
        }
    }
}

Set<String> permSetsExclusivelySharedByAllTargetAssignees = new Set<String>();
for(String permSetName : permSetNameToTotalTargetAssignees.keySet()) {
    if(permSetNameToTotalTargetAssignees.get(permSetName) == targetAssigneeNames.size()) {
        permSetsExclusivelySharedByAllTargetAssignees.add(permSetName);
    }
}

System.debug('Permission Sets Shared Exclusively and Only by Target Users:');
System.debug('->Total:');
System.debug(permSetsExclusivelySharedByAllTargetAssignees.size());
System.debug('->PermSet Names:');
System.debug(permSetsExclusivelySharedByAllTargetAssignees);