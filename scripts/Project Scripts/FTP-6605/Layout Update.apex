String OBJECT_API_NAME = 'Authorization__c';
String PAGE_LAYOUT_NAME = 'Authorization Layout';
String SECTION_NAME = 'Tracking';
String NEW_FIELD_API_NAME = 'Latest_Recycle_User__c';
Boolean NEW_FIELD_UI_READ_ONLY = true;
//Boolean NEW_FIELD_UI_READ_ONLY = false;
String ANCHOR_FIELD_API_NAME = 'Recycled_Count__c';
//String NEW_FIELD_RELATION_TO_ANCHOR = 'BEFORE';
String NEW_FIELD_RELATION_TO_ANCHOR = 'AFTER';

public class ConfigIncompleteException extends Exception{}
if(
        String.isBlank(OBJECT_API_NAME)
                || String.isBlank(PAGE_LAYOUT_NAME)
                || String.isBlank(SECTION_NAME)
                || String.isBlank(NEW_FIELD_API_NAME)
                || String.isBlank(NEW_FIELD_RELATION_TO_ANCHOR)
                || (NEW_FIELD_RELATION_TO_ANCHOR != 'BEFORE') && (NEW_FIELD_RELATION_TO_ANCHOR != 'AFTER')
        ) {
    throw new ConfigIncompleteException('Ensure all Configurations are populated');
}
public class LayoutElementMissingException extends Exception{}

// Add custom field to page layout
// Retrieve layout and section 
List<Metadata.Metadata> layouts =
        Metadata.Operations.retrieve(
                Metadata.MetadataType.Layout,
                new List<String> {OBJECT_API_NAME+'-'+PAGE_LAYOUT_NAME}
        );
if(layouts.size() == 0) {
    throw new LayoutElementMissingException('Layout non-existent');
}
Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(0);
Metadata.LayoutSection layoutSectionToEdit = null;
List<Metadata.LayoutSection> layoutSections = layoutMd.layoutSections;
Boolean layoutSectionFound = false;
for (Metadata.LayoutSection section : layoutSections) {
    if (section.label == SECTION_NAME) {
        layoutSectionToEdit = section;
        layoutSectionFound = true;
        break;
    }
}
if(!layoutSectionFound) {
    throw new LayoutElementMissingException('Section non-existent');
}
// Add the field under section
Integer anchorIndex = null;
List<Metadata.LayoutItem> layoutItems = null;
for(Metadata.LayoutColumn layoutColumn : layoutSectionToEdit.layoutColumns){
    for(Metadata.LayoutItem layoutItem : layoutColumn.layoutItems) {
        if(layoutItem.field == ANCHOR_FIELD_API_NAME) {
            anchorIndex = layoutColumn.layoutItems.indexOf(layoutItem);
            layoutItems = layoutColumn.layoutItems;
            break;
        }
    }
}
if(layoutItems == null) {
    throw new LayoutElementMissingException('Anchor field non-existent');
}
// Create a new layout item for the custom field
Metadata.LayoutItem item = new Metadata.LayoutItem();
item.behavior = NEW_FIELD_UI_READ_ONLY ? Metadata.UiBehavior.Readonly : Metadata.UiBehavior.Edit;
item.field = NEW_FIELD_API_NAME;

switch on NEW_FIELD_RELATION_TO_ANCHOR {
    when 'BEFORE' {
        layoutItems.add(anchorIndex, item);
    }
    when 'AFTER' {
        layoutItems.add(item);
    }
}

for(Metadata.LayoutItem layoutItem : layoutItems) {
    System.debug(layoutItem.field);
}

Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
mdContainer.addMetadata(layoutMd);

// Enqueue custom metadata deployment
Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);