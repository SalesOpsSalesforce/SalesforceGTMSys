@isTest
public class heap_MockDB implements System.StubProvider {
    Integer i = 0;
    List<Object> retvals;

    public heap_MockDB(List<List<SObject>> myRetvals) {
        retvals = myRetvals;
    }

    public Object handleMethodCall(
        Object stubbedObject, String stubbedMethodName,
        Type returnType,
        List<Type> listOfParamTypes,
        List<String> listOfParamNames,
        List<Object> listOfArgs
    ) {
        Object retval = retvals[i];
        i += 1;
        return retval;
    }
}