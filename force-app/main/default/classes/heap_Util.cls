public with sharing class heap_Util {
    //[RGaokar 1/24/2022 TP #92618] Commenting the code to deprecate the heap salesforce integration
    // For code coverage while deploying commented methods
    public heap_Util(){}
    /*public static List<List<Map<String, Object>>> chunk(List<Map<String, Object>> source, Integer chunkSize) {
        List<List<Map<String, Object>>> output = new List<List<Map<String, Object>>>();
        output.add(new List<Map<String, Object>>());
        for (Map<String, Object> datum: source) {
            if (output.get(output.size() - 1).size() == chunkSize) {
                output.add(new List<Map<String, Object>>());
            }
            output.get(output.size() - 1).add(datum);
        }
        return output;
    }

    public static List<List<String>> chunk(List<String> source, Integer chunkSize) {
        List<List<String>> output = new List<List<String>>();
        output.add(new List<String>());
        for (String datum: source) {
            if (output.get(output.size() - 1).size() == chunkSize) {
                output.add(new List<String>());
            }
            output.get(output.size() - 1).add(datum);
        }
        return output;
    }

    public static String base64encodedMD5(String str) {
        return EncodingUtil.base64Encode(Crypto.generateDigest('MD5', Blob.valueOf(str)));
    }*/
}