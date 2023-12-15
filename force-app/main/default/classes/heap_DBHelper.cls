/**
 * This class exists as a means to enable test coverage of queries involving Histories, which are not created
 * during testing.
 *
 * In order to allow for mocking, its methods are not static.
 */
public with sharing class heap_DBHelper {
    /**
     * Return a list of all sObjects whose `idFieldName` column matches `ids`.
     *
     * This could have been quite elegant code if Apex had not removed generic parameterization for lack of use.
     */
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_DBHelper(){}
   /* public List<SObject> getSObjects(String query) {
        return Database.query(query);
    }*/

    /**
     * Return a list of all sObjects whose `idFieldName` column matches `ids`.
     *
     * This could have been quite elegant code if Apex had not removed generic parameterization for lack of use.
     */
   /* public List<SObject> getSObjects(SObjectType type, String idFieldName, List<Id> ids) {
        DescribeSObjectResult describeResult = type.getDescribe();
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        String query =
                ' SELECT ' +
                        String.join( fieldNames, ',' ) +
                        ' FROM ' +
                        describeResult.getName() +
                        ' WHERE ' +
                        idFieldName + ' in :ids'
        ;
        return Database.query(query);
    }*/

}