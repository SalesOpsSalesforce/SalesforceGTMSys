@isTest
public class PaymentCalculatorControllerTest {

    @isTest
    private static void testConstructor() {
        system.assertNotEquals(null, new PaymentCalculatorController());
    }
    
    @isTest
    private static void testCalculatePartnerPayments() {
        system.assertEquals(null, new PaymentCalculatorController().calculatePartnerPayments());
    }
    
    @isTest
    private static void testCalculateOneTimeBounty() {
        system.assertEquals(null, new PaymentCalculatorController().calculateOneTimeBounty());
    }
    
    @isTest
    private static void testCalculateMastersPayment() {
        system.assertEquals(null, new PaymentCalculatorController().calculateMastersPayment());
    }
}