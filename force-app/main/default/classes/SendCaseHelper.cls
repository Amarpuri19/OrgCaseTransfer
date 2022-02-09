public class SendCaseHelper {
    public static Map<String, Case_Transfer__mdt> mapEd = Case_Transfer__mdt.getAll();
    public static Map<String, String> caseMapping = new Map<String, String>();
    public static Map<String, String> caseCommentMapping = new Map<String, String>();
    public static Map<String, String> taskMapping = new Map<String, String>();
    
    @AuraEnabled
    public static void createCase(Id recId){
        //Storing Field Mapping
        
        for(String obj : mapEd.keySet()){
            
            if(mapEd.get(obj).Object_Name__c == 'Case'  && mapEd.get(obj).isActive__c){
                caseMapping.put(mapEd.get(obj).Source_Field__c,mapEd.get(obj).Target_Field__c);
            }else if(mapEd.get(obj).Object_Name__c == 'CaseComment'  && mapEd.get(obj).isActive__c){
                caseCommentMapping.put(mapEd.get(obj).Source_Field__c,mapEd.get(obj).Target_Field__c);
            }else if(mapEd.get(obj).Object_Name__c == 'Task'  && mapEd.get(obj).isActive__c){
                taskMapping.put(mapEd.get(obj).Source_Field__c,mapEd.get(obj).Target_Field__c);
            }
        }
        
        
        string caseFields = string.join(new List<String>(caseMapping.keyset()),',');
        string caseCommentFields =string.join(new List<String>(caseCommentMapping.keyset()),',');
        string taskFields = string.join(new List<String>(taskMapping.keyset()),',');

        String query = 'SELECT '+caseFields+', (SELECT '+caseCommentFields+ ' FROM casecomments) '
            +', (SELECT '+taskFields+' FROM tasks) '+
            ' FROM Case WHERE id=\''+recId+'\'';
        System.debug('Query: '+query);
        Case cs = database.query(query);
        
      
        //Setting Up Callout
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint('callout:Amar_org_v3/services/data/v49.0/composite/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
       	String body = getNewCaseJson(cs);
        
        req.setBody(body);
            Http http = new Http();
            HTTPResponse resp = http.send(req);
            system.debug('Status Code:'+resp.getStatusCode());
            system.debug('Body:'+resp.getBody());
        //End of Callout
    }
    
    public Static string getNewCaseJson(Case cs){
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        
        gen.writeBooleanField('allOrNone', true);
        gen.writeFieldName('compositeRequest');
        gen.writeStartArray();
        gen.writeStartObject();
        	//First Item
        	gen.writeStringField('method', 'PATCH');
            gen.writeStringField('referenceId', 'ref1');
        	gen.writeStringField('url', '/services/data/v49.0/sobjects/Case/External_Case_Id__c/'+cs.Id);
            gen.writeFieldName('body');
        		gen.writeStartObject();
                    for(String filedName :caseMapping.keySet()){
                        if(cs.get(filedName) != null)
                            gen.writeStringField(caseMapping.get(filedName),String.valueOf(cs.get(filedName)));
                    }
        			//gen.writeStringField('Status',cs.Status);
                    //gen.writeStringField('Subject',cs.Subject);
                   // gen.writeStringField('Priority',cs.Priority);
                   // gen.writeStringField('External_Case_Number__c',cs.CaseNumber);
                gen.writeEndObject();
       gen.writeEndObject();
        //Second Object in Array
        integer caseCommentCounter = 0;
        for(casecomment cc: cs.casecomments){
            caseCommentCounter+=1;
            gen.writeStartObject();
        	gen.writeStringField('method', 'POST');
            gen.writeStringField('referenceId', 'caseComment'+caseCommentCounter);
        	gen.writeStringField('url', '/services/data/v49.0/sobjects/CaseComment/');
            gen.writeFieldName('body');
        		gen.writeStartObject();
        			System.debug('Case Comment'+cc);
        			for(String filedName :caseCommentMapping.keySet()){
                        if(cc.get(filedName) != null)
                            gen.writeStringField(caseCommentMapping.get(filedName),String.valueOf(cc.get(filedName)));
                    }
        			
        			gen.writeStringField('parentId', '@{ref1.id}');
        			
        		gen.writeEndObject();
       gen.writeEndObject();
        }
        //Third Object in Array
        integer taskCounter = 0;
        for(Task tk: cs.Tasks){
            taskCounter+=1;
            gen.writeStartObject();
        	gen.writeStringField('method', 'PATCH');
            gen.writeStringField('referenceId', 'task'+taskCounter);
        	gen.writeStringField('url', '/services/data/v49.0/sobjects/task/ExternalId__c/'+tk.Id);
            gen.writeFieldName('body');
        		gen.writeStartObject();
        			System.debug('task '+tk);
        			for(String filedName :taskMapping.keySet()){
                        if(tk.get(filedName) != null)
                            gen.writeStringField(taskMapping.get(filedName),String.valueOf(tk.get(filedName)));
                    }
        			
        			gen.writeStringField('whatId', '@{ref1.id}');
        			
        		gen.writeEndObject();
       gen.writeEndObject();
        }
        
        
       gen.writeEndArray();
       gen.writeEndObject();
        System.debug('JSON>>>: '+gen.getAsString());
        return gen.getAsString();
    }
   
    
}