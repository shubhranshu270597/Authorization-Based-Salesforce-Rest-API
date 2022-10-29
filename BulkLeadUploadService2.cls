/**
 * @description       : 
 * @author            : shubhranshu
 * @group             : 
 * @last modified on  : 10-17-2022
 * @last modified by  : shubhranshu
**/
@RestResource(UrlMapping='/bulkLeadInsertionV2/*')

global class BulkLeadUploadService2 {
    
    @HttpPost
    global static MessageWapper insertLead(){

        String reqString = RestContext.request.requestBody.toString();
        MessageWapper messageWapper = null;
        Map<String,String> headerString = RestContext.request.headers;
        String signature = headerString.containsKey('x-client-signature') ? headerString.get('x-client-signature') : '';
        String clientId = headerString.containsKey('x-client-key') ? headerString.get('x-client-key') : '';
    
        if(String.isNotBlank(signature) && String.isNotBlank(clientId)){
            System.debug('signature '+signature);
            System.debug('clientId '+clientId);
            String resultforAuthHeaders = checkSignatureValue(reqString,signature,clientId);
            if(resultforAuthHeaders != 'success'){
                messageWapper = new MessageWapper('502',resultforAuthHeaders);
                return messageWapper;
            }
            try{
                RestRequest req = RestContext.request;
                String reqBody = (EncodingUtil.base64Decode(req.requestBody.ToString())).toString();
                List<Lead> leads = (List<Lead>) JSON.deserialize(reqBody, List<Lead>.Class);
                Database.insert(leads);
                messageWapper = new MessageWapper('200','Leads Inserted Succssfully.');
                return messageWapper;
            }
            catch(Exception e){
                messageWapper = new MessageWapper('505','Operation Failed. Error: '+e.getMessage());
                return messageWapper;
            }
        }else{
            messageWapper = new MessageWapper('501','client-signature or client-key missing in header.');
            return messageWapper;
        }
    }

    public static String checkSignatureValue(String bodyPayLoad,String Signature,String clientId){
        String result= '';
        List<Api_Access__c> APIAccesslst = Api_Access__c.getall().values();
        if(APIAccesslst.size()>0){
            System.debug('bodyPayLoad '+bodyPayLoad);
            for(Api_Access__c ps:APIAccesslst){
                if(ps.Client_Id__c == clientId && ps.Is_Active__c == true){
                    Blob encString = crypto.generateMac('HmacSHA256',Blob.valueOf(bodyPayLoad), Blob.valueOf(ps.Client_Secret__c));
                    System.debug('encString '+EncodingUtil.convertToHex(encString));
                    if(EncodingUtil.convertToHex(encString) == Signature){
                        result = 'success';
                    }else{
                        result = 'x-client-signature not valid.'; 
                    }
                }else{
                    result = 'x-client-key not matched.';
                }
            }
        }
        return result;
    }

    
    global class MessageWapper
    {
        public String result;
        public String message;
       
        global MessageWapper(String result,String message)
        {
            this.result = result;
            this.message = message;
        }
    }
}