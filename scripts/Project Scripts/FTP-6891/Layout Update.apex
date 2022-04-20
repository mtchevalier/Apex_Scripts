String OBJECT_API_NAME = 'Benefit_Order__c';
String PAGE_LAYOUT_NAME = 'General';
//String PAGE_LAYOUT_NAME = 'Implementation';
//String PAGE_LAYOUT_NAME = 'PCA';
//String PAGE_LAYOUT_NAME = 'Progyny Account Management';
//String PAGE_LAYOUT_NAME = 'Progyny Analytics';
//String PAGE_LAYOUT_NAME = 'Progyny Project Management';
//String PAGE_LAYOUT_NAME = 'Provider Relations';
String NEW_FIELD_API_NAME = 'Claims_Term_Date__c';
//Boolean NEW_FIELD_UI_READ_ONLY = true;
Boolean NEW_FIELD_UI_READ_ONLY = false;
String ANCHOR_FIELD_API_NAME = 'Benefit_Order_End_Date__c';
//String NEW_FIELD_RELATION_TO_ANCHOR = 'BEFORE';
String NEW_FIELD_RELATION_TO_ANCHOR = 'AFTER';

public class ConfigIncompleteException extends Exception{}
if(
        String.isBlank(OBJECT_API_NAME)
                || String.isBlank(PAGE_LAYOUT_NAME)
                || String.isBlank(NEW_FIELD_API_NAME)
                || String.isBlank(NEW_FIELD_RELATION_TO_ANCHOR)
                || (NEW_FIELD_RELATION_TO_ANCHOR != 'BEFORE') && (NEW_FIELD_RELATION_TO_ANCHOR != 'AFTER')
        ) {
    throw new ConfigIncompleteException('Ensure all Configurations are populated');
}
public class LayoutElementMissingException extends Exception{}

List<Metadata.Metadata> layouts =
        Metadata.Operations.retrieve(Metadata.MetadataType.Layout,
                new List<String> {OBJECT_API_NAME+'-'+PAGE_LAYOUT_NAME});
if(layouts.size() == 0) {
    throw new LayoutElementMissingException('Layout non-existent');
}
Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(0);
Metadata.LayoutSection layoutSectionToEdit = null;
List<Metadata.LayoutSection> layoutSections = layoutMd.layoutSections;

List<Metadata.LayoutItem> layoutItems = null;
Integer anchorIndex = null;

for (Metadata.LayoutSection section : layoutSections) {
    for(Metadata.LayoutColumn layoutColumn : section.layoutColumns){
        if((layoutColumn != null) && (layoutColumn.layoutItems != null) && !layoutColumn.layoutItems.isEmpty()) {
            for(Metadata.LayoutItem layoutItem : layoutColumn.layoutItems) {
                if(layoutItem.field == ANCHOR_FIELD_API_NAME) {
                    anchorIndex = layoutColumn.layoutItems.indexOf(layoutItem);
                    layoutItems = layoutColumn.layoutItems;
                    break;
                }
            }
        }
    }
}

if(anchorIndex == null) {
    throw new LayoutElementMissingException('Anchor field not present in layout');
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
        if(anchorIndex == (layoutItems.size() - 1)) {
            layoutItems.add(item);
        } else {
            layoutItems.add(anchorIndex+1, item);
        }
    }
}

for(Metadata.LayoutItem layoutItem : layoutItems) {
    System.debug(layoutItem.field);
}

Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
mdContainer.addMetadata(layoutMd);

// Enqueue custom metadata deployment
Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, null);