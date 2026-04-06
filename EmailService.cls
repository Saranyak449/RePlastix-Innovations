public class EmailService {

    public static void sendWarehouseEmail(Product__c product) {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] {'warehouse@replastix.com'});
        mail.setSubject('Replenishment Approved');

        mail.setPlainTextBody(
            'Product: ' + product.Name +
            '\nStock: ' + product.Stock__c
        );

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
