trigger UpdateStockAfterRestockApproval on Re_Plastic_Innovations_Restock_Request__c (after update) {
    InventoryManager.processRestockApproval(Trigger.new);
}
