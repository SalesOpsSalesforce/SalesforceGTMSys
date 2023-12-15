public with sharing class SupportedFieldTypes {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public SupportedFieldTypes(){}
    /*public static final Set<DisplayType> opportunityAggregateTypes = new Set<DisplayType>{
        DisplayType.Date,
        DisplayType.DateTime,
        DisplayType.Double,
        DisplayType.String,
        DisplayType.Time,
        DisplayType.Currency,
        DisplayType.Percent,
        DisplayType.Id,
        DisplayType.Picklist,
        DisplayType.Reference,
        DisplayType.Phone,
        DisplayType.Email,
        DisplayType.URL
    };

    public static Boolean compareObjects(SObject o1, SObject o2, String field){
        if (null == o1 ) return false;
        if (null == o2 ) return true;

        Object o1Field = o1.get(field);
        Object o2Field = o2.get(field);

        if(o1Field instanceof Id && o2Field instanceof Id)                return (Id)o1Field > (Id)o2Field;
        if(o1Field instanceof String && o2Field instanceof String)        return (String)o1Field > (String)o2Field;
        if(o1Field instanceof Date && o2Field instanceof Date)            return (Date)o1Field > (Date)o2Field;
        if(o1Field instanceof Datetime && o2Field instanceof Datetime)    return (Datetime)o1Field > (Datetime)o2Field;
        if(o1Field instanceof Time && o2Field instanceof Time)            return (Time)o1Field > (Time)o2Field;
        if(o1Field instanceof Integer && o2Field instanceof Integer)      return (Integer)o1Field > (Integer)o2Field;
        if(o1Field instanceof Long && o2Field instanceof Long)            return (Long)o1Field > (Long)o2Field;
        if(o1Field instanceof Decimal && o2Field instanceof Decimal)      return (Decimal)o1Field > (Decimal)o2Field;
        if(o1Field instanceof Double && o2Field instanceof Double)        return (Double)o1Field > (Double)o2Field;
        return False;
    }

    public static Map<String, String> stringifyField(ObjectFieldMapping ofm, SObject record){
        return SupportedFieldTypes.stringifyField(ofm, record, False);
    }

    public static Map<String, String> stringifyField(ObjectFieldMapping ofm, SObject record, Boolean isPrevious){
        Object fieldResult;
        Map<String, String> toRet = new Map<String, String>();

        if (ofm.isReference && null !=record) {
            fieldResult = record.get(ofm.record.ReferenceObjectField__c);
        } else if (null != record) {
            fieldResult = record.get(ofm.record.Field__c);
        } else {
            toRet.put(ofm.getLabel(isPrevious), null);
            return toRet;
        }

        if (fieldResult instanceof System.Address) {
            toRet.put(ofm.getLabel(isPrevious) + ' City', ((Address)fieldResult).getCity());
            toRet.put(ofm.getLabel(isPrevious) + ' Country', ((Address)fieldResult).getCountry());
            toRet.put(ofm.getLabel(isPrevious) + ' Country Code', ((Address)fieldResult).getCountryCode());
            toRet.put(ofm.getLabel(isPrevious) + ' Postal Code', ((Address)fieldResult).getPostalCode());
            toRet.put(ofm.getLabel(isPrevious) + ' Street', ((Address)fieldResult).getStreet());
            toRet.put(ofm.getLabel(isPrevious) + ' State', ((Address)fieldResult).getState());
            toRet.put(ofm.getLabel(isPrevious) + ' State Code', ((Address)fieldResult).getStateCode());
        } else if (fieldResult instanceof System.Location){
            toRet.put(ofm.getLabel(isPrevious) + ' Latitude', String.valueOf(((Location)fieldResult).getLatitude()));
            toRet.put(ofm.getLabel(isPrevious) + ' Longitude', String.valueOf(((Location)fieldResult).getLongitude()));
        } else {
            try {
                toRet.put(ofm.getLabel(isPrevious), String.valueOf(fieldResult));
            } catch (Exception e){
                toRet.put(ofm.getLabel(isPrevious), null);
            }
        }
        return toRet;
    }*/
}