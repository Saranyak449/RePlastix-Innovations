public class OrderHandler {

    public static void updateOrder(Product__c product) {

        if(product.Stock__c < product.Threshold__c) {

            List<Order__c> orders = [
                SELECT Id, Status__c 
                FROM Order__c 
                WHERE Product__c = :product.Id
            ];

            for(Order__c o : orders) {
                o.Status__c = 'Pending Replenishment';
            }

            update orders;
        }
    }
}
