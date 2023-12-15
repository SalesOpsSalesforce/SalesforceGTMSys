public class GeneralUtils implements System.Schedulable {

    // ========== Schedulable functions
    // This was most recently scheduled using the following code:
    //  GeneralUtils.setup();
    //
    // use this method to schedule this job
    public static String cronJobName = 'KAC Monitor Job';
    public static String validUrlRegex = '^((http|https)://)??(www[.])??([a-zA-Z0-9]|-)+?([.][a-zA-Z0-9(-|/|=|?)??]+?)+?$';


    public static void setup() {
        if(Test.isRunningTest()){
            cronJobName += ' test';
        }
        clearPreviousJobs();
        System.schedule(cronJobName, '0 6 * * * ? *', new GeneralUtils());
    }

    @future(callout=true)
    public static void syncRecentlyModifiedRecords(){
        try {
            Datetime d = Datetime.now();
            String soqlQuery;
            List<SObject> queryResult;
            String fromDate = d.addMinutes(-60).formatGMT('yyyy-MM-dd HH:mm:ss|').replace(' ','T').replace('|','Z');
            String toDate = d.formatGMT('yyyy-MM-dd HH:mm:ss|').replace(' ','T').replace('|','Z');
            Map<String,Object> properties = new Map<String,Object>();

            // Loop through desired sobjects and find out how many of each were modified in the last 30 mins
            List<String> sobjs = new List<String> {
                'Account',
                    'Customer_Onboarding__c',
                    'Lead'
                    };
                        for(String sobj: sobjs){
                            soqlQuery =
                                'SELECT Id,LastModifiedDate ' +
                                'FROM ' + sobj + ' ' +
                                'WHERE LastModifiedDate > '+ fromDate +' ' +
                                'AND LastModifiedDate < '+ toDate +'';
                            queryResult = Database.query(soqlQuery);
                            properties.put(sobj, queryResult.size());
                        }

            // Assemble the rest of the Track payload
            properties.put('FromDate',d.addMinutes(-60).formatGMT('yyyy-MM-dd HH:mm:ss'));
            properties.put('ToDate',d.formatGMT('yyyy-MM-dd HH:mm:ss'));

            Map<String,Object> customerProperties = new Map<String,Object>();
            customerProperties.put('$email','walid.bendris+kac@klaviyo.com');

            // Make a track request
            // Retrieve keys for current key set
            Map <String, String> apiKeys = GeneralUtils.getMetadataTypeValuesByLabel('KlaviyoAPIAccount__mdt','TestAccount');
            ApexKlaviyoAPI klaviyoClient = new ApexKlaviyoAPI(apiKeys);

            klaviyoClient.track(
                klaviyoClient.buildTrackPayload('Salesforce Records Modified', customerProperties, properties)
            );

        } catch (Exception ex) {
            GeneralUtils.logException(ex);
        }
    }

    public void execute(SchedulableContext context) {
        GeneralUtils.syncRecentlyModifiedRecords();
    }
    // clears previous scheduled jobs
    public static void clearPreviousJobs() {
        CronTrigger[] lstJob = getCurrentCronTriggers();
        for (CronTrigger cr : lstJob) {
            System.abortJob(cr.Id);
        }
    }
    // query for scheduled jobs for this class
    // @return list of Scheduled Jobs
    public static List<CronTrigger> getCurrentCronTriggers() {
        return [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :cronJobName
        ];
    }
    public static void clearPreviousJob(String providedCronJobName) {
        CronTrigger[] lstJob = getCurrentCronTrigger(providedCronJobName);
        for (CronTrigger cr : lstJob) {
            System.abortJob(cr.Id);
        }
    }
    // query for scheduled jobs for this class
    // @return list of Scheduled Jobs
    public static List<CronTrigger> getCurrentCronTrigger(String providedCronJobName) {
        return [
            SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
            FROM CronTrigger
            WHERE CronJobDetail.Name = :providedCronJobName
        ];
    }


    // Check if the domain is invalid
    public static Boolean isValidUrl(String url) {
        // Return false immediately if the URL doesnt exist
        if (url == Null || url == ''){
            return false;
        }
        // If a URL was sent, do some regex pattern matching
        Pattern validUrlRegexPattern = Pattern.compile(GeneralUtils.validUrlRegex);
        Matcher urlValidationMatcher = validUrlRegexPattern.matcher(url);
        return urlValidationMatcher.matches();
    }


    public static void logException(Exception ex) {
        System.debug('Exception: "' + ex.getMessage() +
                     '" of type "' + ex.getTypeName() +
                     '" caused by "' + ex.getCause() +
                     '" on line number ' + ex.getLineNumber() + '\n' +
                     'Stack Trace: ' + ex.getStackTraceString());
    }

    public static void logRequest(HttpRequest request, HTTPResponse response) {
        System.debug('Method: "' + request.getMethod() + '"' + '\n' +
                     'Endpoint: "' + request.getEndpoint() + '"' + '\n' +
                     'Content-Type Header: "' + request.getHeader('Content-Type') + '"' + '\n' +
                     //'Authorization Header: "' + request.getHeader('Authorization') + '"' + '\n' +
                     //'x-api-key Header: "' + request.getHeader('x-api-key') + '"' + '\n' +
                     'Body: "' + request.getBody() + '"');
        System.debug(response.toString());
        //System.debug(response.getBody());
    }

    public static void logRequestException(HttpRequest request, Exception ex) {
        System.debug('Method: "' + request.getMethod() + '"' + '\n' +
                     'Endpoint: "' + request.getEndpoint() + '"' + '\n' +
                     'Content-Type Header: "' + request.getHeader('Content-Type') + '"' + '\n' +
                     //'Authorization Header: "' + request.getHeader('Authorization') + '"' + '\n' +
                     //'x-api-key Header: "' + request.getHeader('x-api-key') + '"' + '\n' +
                     'Body: "' + request.getBody() + '"');
        GeneralUtils.logException(ex);
    }

    public static Long dateStringToUnix(String dstr){
        String datestr = dstr.split('T')[0];
        String timestr = dstr.split('T')[1].split('\\.')[0];
        Datetime dt = Datetime.valueOf(datestr + ' ' + timestr);
        return dt.getTime() / 1000;
    }

    public static Long datetimeToUnix(Datetime dt){
        return dt.getTime() / 1000;
    }

    public static String getSobjectTypeFromSet(Set<SObject> sobjects) {
        if (sobjects.size() == 0){
            return null;
        }
        // Convert set to List to retrieve elements
        List<SObject> typeCheckList = new List<SObject>(sobjects);
        // Get the SObject type of the first list element as a string
        return typeCheckList[0].getSObjectType().getDescribe().getName();
    }

    public static String paramMapToString(Map<String,String> paramsMap){
        String params = '?';
        if(paramsMap.size() > 0){
            for (String paramKey : paramsMap.keySet()){
                params += EncodingUtil.URLENCODE(paramKey,'UTF-8') + '=' +
                    EncodingUtil.URLENCODE(paramsMap.get(paramKey),'UTF-8') + '&';
            }
        }
        else {
            return '';
        }
        return params.substring(0, params.length()-1);
    }

    public static String getTpGeneralUserId(String accessToken, String email, String userType){
        String requestUrl = 'https://klaviyo.tpondemand.com/api/v1/GeneralUser';
        Map<String,String> paramsMap = new Map<String,String>{
            'access_token' => accessToken,
                'include' => '[Id,Email,FullName]',
                'where' => 'Email contains "'+email+'"'
                };
        String params = GeneralUtils.paramMapToString(paramsMap);
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(5000);
        request.setMethod('GET');
        request.setEndpoint(requestUrl+params);
        // Send request
        HTTP http = new HTTP();
        HTTPResponse res;
        try {
            res = http.send(request);
            GeneralUtils.logRequest(request, res);
        } catch (System.CalloutException ex) {
            GeneralUtils.logRequestException(request, ex);
        }
        // Parse response to get TargetProcess GeneralUser Id
        String tpUserId = null;
        if (res!=null) {
            DOM.Document doc = res.getBodyDocument();
            list<string> urls=new list<string>();
            for(Dom.XmlNode generalUserNode : doc.getRootElement().getChildElements()) {
                if(generalUserNode.getChildElement('Kind',null).getText() == userType) {
                    tpUserId = generalUserNode.getAttribute('Id', null);
                }
            }
        }
        return tpUserId;
    }

    public static String createNewTpRequester(ApexKlaviyoAPI klaviyoClient, String accessToken, String firstName, String lastName, String email){
        // Create new Requester on the TargetProcess Bug Portal
        String requestUrl = 'https://klaviyo.tpondemand.com/api/v1/Requesters';
        Map<String,String> paramsMap = new Map<String,String>{
            'access_token' => accessToken
        };
        String params = GeneralUtils.paramMapToString(paramsMap);
        String requestBody = '{' +
            '"FirstName": "' + firstName + '",' +
            '"LastName": "' + lastName + '",' +
            '"Email": "' + email + '"' +
        '}';
        // Build request
        HttpRequest request = new HttpRequest();
        request.setTimeout(5000);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(requestUrl+params);
        request.setBody(requestBody);
        // Send request
        HTTP http = new HTTP();
        HTTPResponse res;
        try {
            res = http.send(request);
            GeneralUtils.logRequest(request, res);
        } catch (System.CalloutException ex) {
            GeneralUtils.logRequestException(request, ex);
        }

        // Parse response to get TargetProcess GeneralUser Id
        klaviyoClient.track(
            klaviyoClient.buildTrackPayload(
                'Requested Internal Tool Access',
                new Map<String,Object>{'$email' => email},
                new Map<String,Object>{
                    'TotalRequests' => 1,
                    'RequestedTools' => new List<String>{'Klaviyo Bug Portal'}
                }
            )
        );
        return getTpGeneralUserId(accessToken, email, 'Requester');
    }

    public static Map <String,String> cleanMetadataMap(Map <String,String> fieldMap, String objectType){
        // Make sure field exists on SObject. If not, remove it.
        Set<String> keys = fieldMap.keySet();
        Set<String> objectFields = new Set<String>();
        if (objectType == 'Account') {
            objectFields = Schema.SObjectType.Account.fields.getMap().keySet();
        } else if (objectType == 'Case') {
            objectFields = Schema.SObjectType.Case.fields.getMap().keySet();
        } else if (objectType == 'Lead') {
            objectFields = Schema.SObjectType.Lead.fields.getMap().keySet();
        } else if (objectType == 'Customer_Onboarding__c') {
            objectFields = Schema.SObjectType.Customer_Onboarding__c.fields.getMap().keySet();
        }
        for (String key: keys) {
            if (!objectFields.contains(fieldMap.get(key).toLowerCase())){
                keys.remove(key);
            }
        }
        fieldMap.keySet().retainAll(keys);
        return fieldMap;
    }

    // Retrieve all values and labels from given MDT object as a Map
    public static Map <String, String> getMetadataTypeCustomFieldMap(String mdtName) {
        Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(mdtName).getDescribe().fields.getMap();
        Map <String, String> fields = new Map <String, String>();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.getname().indexOf('__c') != -1){
                fields.put(dfield.getname(), dfield.getLabel());
            }
        }
        return fields;
    }

    // Retrieve all values and labels from given MDT by Label record as a Map
    public static Map <String, String> getMetadataTypeValuesByLabel(String mdtName, String mdtLabel) {
        Map <String, String> fields = GeneralUtils.getMetadataTypeCustomFieldMap(mdtName);
        String queryFields = String.join(new List<String>(fields.keySet()), ',');
        //String queryFields = String.join(fields.keySet(),',');
        String soqlQuery = 'SELECT '+queryFields+' FROM '+mdtName+' WHERE Label=\''+mdtLabel+'\' LIMIT 1';
        // Retrieve custom fields from MDT
        Map<String,Object> fieldMap = new Map<String,Object>();
        fieldMap = Database.query(soqlQuery).get(0).getPopulatedFieldsAsMap();
        // Id is automatically retrieved so remove it
        Set<String> keys = fieldMap.keySet();
        keys.remove('Id');
        fieldMap.keySet().retainAll(keys);
        // Make different Map where the object labels are the keys (instead of the API names)
        Map<String,String> fieldMapToReturn = new Map<String,String>();
        for (String fieldName: fields.keySet()) {
            fieldMapToReturn.put(
                fields.get(fieldName),
                fieldMap.keySet().contains(fieldName) ? fieldMap.get(fieldName).toString() : ''
            );
        }
        // Return map of field label keys (the profile property name in Klaviyo) to their set values (the API name of the field in Salesforce).
        return fieldMapToReturn;
    }

    // Retrieve all values and labels from given MDT by Id record as a Map
    public static Map <String, String> getMetadataTypeValuesById(String mdtName, String mdtId) {
        Map <String, String> fields = GeneralUtils.getMetadataTypeCustomFieldMap(mdtName);
        String queryFields = String.join(new List<String>(fields.keySet()), ',');
        //String queryFields = String.join(fields.keySet(),',');
        String soqlQuery = 'SELECT '+queryFields+' FROM '+mdtName+' WHERE Id=\''+mdtId+'\' LIMIT 1';
        // Retrieve custom fields from MDT
        Map<String,Object> fieldMap = new Map<String,Object>();
        fieldMap = Database.query(soqlQuery).get(0).getPopulatedFieldsAsMap();
        // Id is automatically retrieved so remove it
        Set<String> keys = fieldMap.keySet();
        keys.remove('Id');
        fieldMap.keySet().retainAll(keys);
        // Make different Map where the object labels are the keys (instead of the API names)
        Map<String,String> fieldMapToReturn = new Map<String,String>();
        for (String fieldName: fields.keySet()) {
            fieldMapToReturn.put(
                fields.get(fieldName),
                fieldMap.keySet().contains(fieldName) ? fieldMap.get(fieldName).toString() : ''
            );
        }
        // Return map of field label keys (the profile property name in Klaviyo) to their set values (the API name of the field in Salesforce).
        return fieldMapToReturn;
    }

    /*public static Map<Id,String> getNamesFromId(Map<String,List<Id>> sobjectIdMap){
        // Takes a map of sobject types to a list of IDs
        // Returns a map of Ids to Names

        Map<Id,String> idToNameMap = new Map<Id,String>();

        // Get all accounts in Account Id list
        Map<ID,Account> accountList = new Map<ID,Account>(
            [SELECT Id,Name FROM Account WHERE Id In :sobjectIdMap.get('Account')]);
        for(ID accountListId : accountList.keySet()){
            idToNameMap.put(accountListId, (String)accountList.get(accountListId)?.get('Name'));
        }
        // Get all users in User Id list
        Map<ID,User> userList = new Map<ID,User>(
            [SELECT Id,Name FROM User WHERE Id In :sobjectIdMap.get('User')]);
        for(ID userListId : userList.keySet()){
            idToNameMap.put(userListId, (String)userList.get(userListId)?.get('Name'));
        }

        return idToNameMap;
    }*/

    public static Set<String> removeBlanksFromSet(Set<String> setWithBlanks){
        Set<String> setWithoutBlanks = new Set<String>(setWithBlanks);
        setWithoutBlanks.remove('');
        setWithoutBlanks.remove(null);
        return setWithoutBlanks;
    }

}