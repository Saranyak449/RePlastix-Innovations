trigger ProductTrigger on Product__c (after update) {

    for(Product__c p : Trigger.new) {
        Product__c oldP = Trigger.oldMap.get(p.Id);

        if(p.Stock__c < p.Threshold__c && oldP.Stock__c >= oldP.Threshold__c) {

            Task t = new Task(
                Subject = 'Low Stock Alert',
                WhatId = p.Id,
                OwnerId = p.OwnerId,
                Status = 'Not Started',
                Priority = 'High'
            );

            insert t;
        }
    }
}
