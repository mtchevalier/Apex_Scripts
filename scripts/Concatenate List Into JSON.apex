List<String> strs = new List<String>{
        '94086',
        '94087',
        '94085',
        '94089'
};
String json = '[';
for(Integer i=0; i<strs.size(); i++){
    json += ('"'+strs[i]+'"');
    if(i != strs.size()-1) {
        json += ',';
    }
}
json += ']';
System.debug('\n\n\nvvvvvvvvvvvvvvvvvvvvvvvvJSON BELOWvvvvvvvvvvvvvvvvvvvvvvvv');
System.debug('\n\n\n'+json+'\n\n\n');
System.debug('\n^^^^^^^^^^^^^^^^^^^^^^^^JSON ABOVE^^^^^^^^^^^^^^^^^^^^^^^^\n\n\n');
