@isTest
public class SendCaseHelperTest {
    @testSetup static void setup() {
        Case cs = new Case(Subject='Test Case',Priority='Medium',Status='New');
        insert cs;
        List<CaseComment> ccList = new List<CaseComment>();
        List<task> tkList = new List<task>();
        for(integer i = 0 ; i < 5 ; i++){
            CaseComment cc = new CaseComment(parentId = cs.Id , commentbody = 'Test Body: '+i);
            Task tk = new Task(Subject = 'Test Task'+i, Description = 'Test',whatId = cs.Id);
            ccList.add(cc);
            tkList.add(tk);
        }
        insert tkList;
        insert ccList;
    }
    @isTest
    private static void caseMigrate(){
        Case cs = [Select id, caseNumber, Status, Priority,
                   Subject,(SELECT CommentBody FROM CaseComments),
                   (SELECT  Subject,Description FROM Tasks)
                   FROM Case
                  Limit 1];
        test.startTest();
        test.setMock(HttpCalloutMock.class, new caseTransfer());
        SendCaseHelper.createCase(cs.Id);
        test.stopTest();
        
    }
    
    public class caseTransfer implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String body = '{'+
                          '"compositeResponse": ['+
                            '{'+
                              '"body": {'+
                               ' "id": "5002v000032vJCYAA2",'+
                              '  "success": true,'+
                              '  "errors": [],'+
                             '   "created": false'+
                             ' },'+
                             ' "httpHeaders": {'+
                             '   "Location": "/services/data/v49.0/sobjects/Case/5002v000032vJCYAA2"'+
                            '  },'+
                              '"httpStatusCode": 200,'+
                             ' "referenceId": "ref1"'+
                '}]}';
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
}