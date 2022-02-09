({
	doInit : function(cmp, event, helper) {
        console.log('ID '+cmp.get("v.recordId"));
		var action = cmp.get("c.createCase");
        action.setParams({ recId : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type":"SUCCESS",
                    "title": "Success!",
                    "message": "The record has been updated successfully."
                });
                toastEvent.fire();
                var navService = cmp.find("navService");
                var pageReference = {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: cmp.get("v.recordId"),
                        objectApiName: 'Case',
                        actionName: "view"
                    }
                };
                navService.navigate(pageReference);
            }else{
                alert('Error');
            }
        });
        $A.enqueueAction(action);
	},
    handleClick : function (cmp, event, helper) {
        //alert("You clicked: " + event.getSource().get("v.label"));
        var action = cmp.get("c.createCase");
        action.setParams({ recId : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //success
            }else{
                alert('Error');
            }
        });
        $A.enqueueAction(action);
    }
})