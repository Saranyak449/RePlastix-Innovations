public class InventoryManager {

    // === Method to process stock reduction after an order ===
    public static void processOrderStock(List<Re_Plastic_Innovations_Order__c> orderList) {

        if(orderList == null || orderList.isEmpty()) return;

        // Replace this with your actual lookup field on the Order object
        // Example: Product_Lookup__c
        String orderProductField = 'Product__c'; 

        Set<Id> productIds = new Set<Id>();
        for (Re_Plastic_Innovations_Order__c order : orderList) {
            if(order.get(orderProductField) != null) {
                productIds.add((Id)order.get(orderProductField));
            }
        }

        if(productIds.isEmpty()) return;

        // Query product stock levels
        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productMap =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>(
                [SELECT Id, Stock_Level_c, Threshold_c
                 FROM Re_Plastic_Innovations_Recycled_Product__c
                 WHERE Id IN :productIds]
            );

        List<Re_Plastic_Innovations_Recycled_Product_c> productsToUpdate = new List<Re_Plastic_Innovations_Recycled_Product_c>();
        List<Re_Plastic_Innovations_Restock_Request_c> restockRequests = new List<Re_Plastic_Innovations_Restock_Request_c>();
        List<Task> tasksToInsert = new List<Task>();

        for (Re_Plastic_Innovations_Order__c order : orderList) {
            Id productId = (Id)order.get(orderProductField);
            if(productId == null) continue;

            Re_Plastic_Innovations_Recycled_Product__c product = productMap.get(productId);
            if(product == null) continue;

            Decimal stock = product.Stock_Level_c == null ? 0 : product.Stock_Level_c;
            Decimal qty = order.Quantity_c == null ? 0 : order.Quantity_c;

            if(stock >= qty) {
                product.Stock_Level__c = stock - qty;
            } else {
                // Replace this with your actual lookup field on Restock Request
                // Example: Recycled_Product_Lookup__c
                restockRequests.add(new Re_Plastic_Innovations_Restock_Request__c(
                    Recycled_Product__c = product.Id,
                    Requested_Quantity__c = qty - stock,
                    Status__c = 'Pending'
                ));
                product.Stock_Level__c = 0;
            }

            productsToUpdate.add(product);

            if(product.Threshold_c != null && product.Stock_Levelc <= product.Threshold_c) {
                tasksToInsert.add(new Task(
                    Subject = 'Low Stock Alert',
                    Description = 'Stock level is below threshold for this product.',
                    WhatId = product.Id,
                    OwnerId = UserInfo.getUserId(),
                    Status = 'Not Started',
                    Priority = 'High'
                ));
            }
        }

        if(!productsToUpdate.isEmpty()) update productsToUpdate;
        if(!restockRequests.isEmpty()) insert restockRequests;
        if(!tasksToInsert.isEmpty()) insert tasksToInsert;
    }

    // === Method to process stock increase after restock approval ===
    public static void processRestockApproval(List<Re_Plastic_Innovations_Restock_Request__c> restockList) {

        if(restockList == null || restockList.isEmpty()) return;

        // Replace this with your actual lookup field on Restock Request
        // Example: Recycled_Product_Lookup__c
        String restockProductField = 'Recycled_Product__c';

        Set<Id> productIds = new Set<Id>();
        for(Re_Plastic_Innovations_Restock_Request__c restock : restockList) {
            if(restock.Status__c == 'Approved' && restock.get(restockProductField) != null) {
                productIds.add((Id)restock.get(restockProductField));
            }
        }

        if(productIds.isEmpty()) return;

        Map<Id, Re_Plastic_Innovations_Recycled_Product__c> productMap =
            new Map<Id, Re_Plastic_Innovations_Recycled_Product__c>(
                [SELECT Id, Stock_Level__c
                 FROM Re_Plastic_Innovations_Recycled_Product__c
                 WHERE Id IN :productIds]
            );

        List<Re_Plastic_Innovations_Recycled_Product_c> productsToUpdate = new List<Re_Plastic_Innovations_Recycled_Product_c>();

        for(Re_Plastic_Innovations_Restock_Request__c restock : restockList) {
            if(restock.Status__c != 'Approved') continue;

            Id productId = (Id)restock.get(restockProductField);
            if(productId == null || !productMap.containsKey(productId)) continue;

            Re_Plastic_Innovations_Recycled_Product__c product = productMap.get(productId);

            Decimal currentStock = product.Stock_Level_c == null ? 0 : product.Stock_Level_c;
            Decimal qty = restock.Requested_Quantity_c == null ? 0 : restock.Requested_Quantity_c;

            product.Stock_Level__c = currentStock + qty;
            productsToUpdate.add(product);
        }

        if(!productsToUpdate.isEmpty()) update productsToUpdate;

        // Send notification
        EmailNotificationHelper.sendRestockNotification(restockList);
    }
}
