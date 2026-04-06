trigger UpdateStockAfterOrder on Re_Plastic_Innovations_Order__c (after insert) {
    InventoryManager.processOrderStock(Trigger.new);
}
