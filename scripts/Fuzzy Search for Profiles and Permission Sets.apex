List<String> tokens = new List<String>{
  'PCA', 'Clinical'  
};

String profileQuery =
        'SELECT Name\n ' +
        'FROM Profile\n ' +
        'WHERE ';

String permSetQuery = 
        'SELECT Name\n ' +
        'FROM PermissionSet\n ' +
        'WHERE '; 

for(Integer i=0; i < tokens.size(); i++) {
    profileQuery += 'Name LIKE \'%' + tokens[i] + '%\' ';
    permSetQuery += 'Name LIKE \'%' + tokens[i] + '%\' ';
    if(i != (tokens.size() - 1)) {
        profileQuery += '\n OR ';
        permSetQuery += '\n OR ';
    }
}

String profileResults = '';
String permSetResults = '';

for(Profile profile : Database.query(profileQuery)) {
    profileResults += '\n\t'+profile.Name;
}

for(PermissionSet permSet : Database.query(permSetQuery)) {
    permSetResults += '\n\t'+permSet.Name;
}

System.debug(
        '\n\n ' +
        'PROFILE QUERY:' +
        '\n\n ' +
        profileQuery + 
        '\n\n' +
        'PERMISSION SET QUERY:' +
        '\n\n ' +
        permSetQuery + 
        '\n\n' +
        'PROFILES:' +
        profileResults +
        '\n\n' +
        'PERMISSION SETS:' +
        permSetResults
);