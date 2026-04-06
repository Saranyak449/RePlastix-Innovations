@isTest
public class InventoryManagerTest {

    @testSetup
    static void setupTestData() {

        // Create a product with initial stock of 50
        Re_Plastic_Innovations_Recycled_Product__c product =
            new Re_Plastic_Innovations_Recycled_Product__c(
                Stock_Level__c = 50,
                Threshold__c = 10
            );
        insert product;

        // Create orders
        List<Re_Plastic_Innovations_Order__c> orders =
            new List<Re_Plastic_Innovations_Order__c>{
                new Re_Plastic_Innovations_Order__c(
                    Recycled_Product__c = product.Id,
                    Quantity__c = 20
                ),
                new Re_Plastic_Innovations_Order__c(
                    Recycled_Product__c = product.Id,
                    Quantity__c = 40
                )
            };
        insert orders;
    }

    @isTest
    static void testProcessOrderStock() {

        List<Re_Plastic_Innovations_Order__c> orders = [
            SELECT Id, Recycled_Product_c, Quantity_c
            FROM Re_Plastic_Innovations_Order__c
        ];

        Test.startTest();
        InventoryManager.processOrderStock(orders);
        Test.stopTest();

        // Check updated stock
        Re_Plastic_Innovations_Recycled_Product__c product = [
            SELECT Stock_Level__c
            FROM Re_Plastic_Innovations_Recycled_Product__c
            LIMIT 1
        ];

        System.assertEquals(30, product.Stock_Level__c, 'Stock should reduce correctly');

        // Check restock request
        List<Re_Plastic_Innovations_Restock_Request__c> restockRequests = [
            SELECT Id, Status__c
            FROM Re_Plastic_Innovations_Restock_Request__c
            WHERE Status__c = 'Pending'
        ];

        System.assertEquals(1, restockRequests.size(), 'Only one restock request should be created');
    }

    @isTest
    static void testProcessRestockApproval() {

        Re_Plastic_Innovations_Recycled_Product__c product = [
            SELECT Id, Stock_Level__c
            FROM Re_Plastic_Innovations_Recycled_Product__c
            LIMIT 1
        ];

        List<Re_Plastic_Innovations_Restock_Request__c> restocks =
            new List<Re_Plastic_Innovations_Restock_Request__c>{
                new Re_Plastic_Innovations_Restock_Request__c(
                    Product__c = product.Id,
                    Requested_Quantity__c = 30,
                    Status__c = 'Approved'
                ),
                new Re_Plastic_Innovations_Restock_Request__c(
                    Product__c = product.Id,
                    Requested_Quantity__c = 20,
                    Status__c = 'Approved'
                )
            };
        insert restocks;

        Decimal initialStock = product.Stock_Level__c;

        Decimal totalRestockQuantity = 0;
        for (Re_Plastic_Innovations_Restock_Request__c req : restocks) {
            totalRestockQuantity += req.Requested_Quantity__c;
        }

        Test.startTest();
        InventoryManager.processRestockApproval(restocks);
        Test.stopTest();

        Re_Plastic_Innovations_Recycled_Product__c productAfter = [
            SELECT Stock_Level__c
            FROM Re_Plastic_Innovations_Recycled_Product__c
            WHERE Id = :product.Id
        ];

        Decimal expectedStock = initialStock + totalRestockQuantity;

        System.assertEquals(
            expectedStock,
            productAfter.Stock_Level__c,
            'Stock should increase correctly after restock approval'
        );
    }
}
